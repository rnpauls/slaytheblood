## Visualizes a CardPile as a vertical stack of cards anchored to the bottom of
## the screen. Used for both the player's draw pile (face-down, bottom-left) and
## the player's discard pile (face-up, bottom-right). Each card in the resource
## pile maps to one CardUI child here; when the resource pile mutates,
## visuals are spawned/freed to match.
##
## Drawing & discarding hand cards are handoffs, not spawn/free: the live
## CardUI travels physically into or out of this panel via release_top_visual()
## and accept_incoming_visual(). Both must be called BEFORE the resource pile
## mutates so the size_changed handler sees matching counts and skips the
## auto-sync.
class_name CardStackPanel
extends Control

signal pressed

const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

# Card geometry (must match card_ui.tscn).
const CARD_SIZE_UNSCALED := Vector2(200, 280)
const CARD_PIVOT := Vector2(100, 140)

# Visible scale of cards while in the pile.
const PILE_SCALE := 0.6
# Fraction of the card height that peeks above the bottom of the screen for the
# bottom-most card. Each card stacked above adds another `per_card_offset`.
const TOP_VISIBLE_FRAC := 0.2
# Animation timing.
const REARRANGE_DURATION := 0.18
const ZOOM_DURATION := 0.15

const SIDE_LEFT := 0
const SIDE_RIGHT := 1

@export var card_pile: CardPile : set = set_card_pile
## When true, new visuals show the card-back; when false, the face is visible.
@export var face_down: bool = true
## Anchor side for hover-preview clamping of the top card. 0=LEFT, 1=RIGHT.
@export_enum("LEFT", "RIGHT") var anchor_side: int = SIDE_LEFT

@onready var click_area: Button = %ClickArea
@onready var counter: Label = %Counter

var _hovered: bool = false
# When non-null, this card is in the zoomed-preview state and skips normal layout.
var _zoomed_top: CardUI = null


func _ready() -> void:
	click_area.mouse_entered.connect(_on_pile_hover_entered)
	click_area.mouse_exited.connect(_on_pile_hover_exited)
	click_area.pressed.connect(func(): pressed.emit())


func set_card_pile(value: CardPile) -> void:
	if card_pile and card_pile.card_pile_size_changed.is_connected(_on_pile_size_changed):
		card_pile.card_pile_size_changed.disconnect(_on_pile_size_changed)
	card_pile = value
	if not is_node_ready():
		await ready
	if card_pile and not card_pile.card_pile_size_changed.is_connected(_on_pile_size_changed):
		card_pile.card_pile_size_changed.connect(_on_pile_size_changed)
	_sync_to_resource()


# ── Public handoff API ────────────────────────────────────────────────────────

## Detach the visually-topmost card and return it. The caller is expected to
## reparent it (e.g. into Hand) and then mutate the resource pile via
## draw_card(). The subsequent size_changed handler will see counts already
## match and skip auto-removal.
func release_top_visual() -> CardUI:
	var visuals := _visuals()
	if visuals.is_empty():
		return null
	var top: CardUI = visuals.back()
	if top == _zoomed_top:
		_zoomed_top = null
	var gpos: Vector2 = top.global_position
	var grot: float = top.rotation_degrees
	var gscale: Vector2 = top.scale
	remove_child(top)
	top.global_position = gpos
	top.rotation_degrees = grot
	top.scale = gscale
	# Caller takes ownership; rearrange remaining stack.
	_arrange()
	return top


## Accept an existing CardUI as the new top of the stack. Caller should call
## this BEFORE mutating the resource pile via add_card(). The card_ui keeps its
## current global transform (no visual jump on reparent) and tweens to its slot.
func accept_incoming_visual(card_ui: CardUI) -> void:
	# Kill any in-flight tween from the previous parent (e.g. Hand's _arrange_cards),
	# otherwise it'll keep interpolating toward stale local-space targets after reparent.
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()
	var gpos: Vector2 = card_ui.global_position
	var prev_parent: Node = card_ui.get_parent()
	if prev_parent:
		prev_parent.remove_child(card_ui)
	add_child(card_ui)
	move_child(card_ui, get_child_count() - 1)  # last child = visual top
	# Preserve only the y of the hand-spot so the fly-in slides DOWN into the
	# slot. Snap x to the slot column immediately so the discard column stays
	# vertically aligned during the fly-in (otherwise multiple cards mid-tween
	# would each be at a different x). Snap rotation and scale to pile values
	# for the same reason.
	card_ui.global_position = gpos
	card_ui.position = Vector2(_slot_position(0).x, card_ui.position.y)
	card_ui.rotation_degrees = 0.0
	card_ui.scale = Vector2(PILE_SCALE, PILE_SCALE)
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# CardRenderContainer and its descendants default to MOUSE_FILTER_STOP and would
	# otherwise capture hover events before they reach the panel's ClickArea sibling.
	_set_descendants_mouse_filter(card_ui, Control.MOUSE_FILTER_IGNORE)
	card_ui.z_index = 0
	if card_ui.card_render:
		card_ui.card_render.show_back = face_down
	_arrange()


func _set_descendants_mouse_filter(node: Node, filter: int) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = filter
		_set_descendants_mouse_filter(child, filter)


# ── Internal: spawn/free to match resource size ───────────────────────────────

func _on_pile_size_changed(_new_size: int) -> void:
	_sync_to_resource()


func _sync_to_resource() -> void:
	if not card_pile:
		return
	var visuals := _visuals()
	var diff := card_pile.cards.size() - visuals.size()
	if diff > 0:
		for i in diff:
			_spawn_back()
	elif diff < 0:
		# Excess visuals — free from the top down. Normal play uses release_top_visual()
		# instead, so this path only triggers if a resource mutation happened without
		# a handoff (defensive).
		for i in -diff:
			var top: CardUI = _visuals().back()
			if top == _zoomed_top:
				_zoomed_top = null
			top.queue_free()
	_update_counter()
	_arrange()


func _spawn_back() -> void:
	var visual := CARD_UI_SCENE.instantiate() as CardUI
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	# scene `ready` runs on add_child; show_back's await ready resolves immediately.
	visual.card_render.show_back = face_down
	_set_descendants_mouse_filter(visual, Control.MOUSE_FILTER_IGNORE)
	# Spawn off-screen below; _arrange will tween it into place.
	visual.position = _slot_position(0) + Vector2(0, 200)
	visual.scale = Vector2(PILE_SCALE, PILE_SCALE)


func _update_counter() -> void:
	if counter and card_pile:
		counter.text = str(card_pile.cards.size())


# ── Layout ───────────────────────────────────────────────────────────────────

func _visuals() -> Array[CardUI]:
	var out: Array[CardUI] = []
	for child in get_children():
		if child is CardUI:
			out.append(child)
	return out


## Local-space position for a card at stack index i.
## i=0 (first child, drawn BEHIND) sits at the visual top of the column
## (most-north, smallest y). i=N-1 (drawn ON TOP) sits at the bottom of the
## column (most-south). The most-recently-added card (last child) is therefore
## the most-south one — fully visible, with older cards' top edges peeking
## above it. Same ordering for both piles.
func _slot_position(i: int) -> Vector2:
	var n := _visuals().size()
	var max_height: float = 70.0 if _hovered else 50.0
	var max_per_card: float = 30.0 if _hovered else 20.0
	var per_card_offset: float = 0.0
	if n > 1:
		per_card_offset = minf(max_per_card, max_height / float(n - 1))
	var card_height_visible: float = CARD_SIZE_UNSCALED.y * PILE_SCALE
	var top_visible_band: float = TOP_VISIBLE_FRAC * card_height_visible
	var bottom_top_y: float = size.y - top_visible_band
	var step: int = n - 1 - i
	var visible_top_y: float = bottom_top_y - step * per_card_offset
	# Convert visible-top-left to Control.position by subtracting the pivot offset
	# induced by Control scaling around pivot_offset.
	var visible_top_left := Vector2(0, visible_top_y)
	return visible_top_left - (1.0 - PILE_SCALE) * CARD_PIVOT


func _arrange() -> void:
	var visuals := _visuals()
	var n := visuals.size()
	if n == 0:
		return
	for i in n:
		var card := visuals[i]
		if card == _zoomed_top:
			continue
		var target_pos := _slot_position(i)
		var t := card.create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		t.tween_property(card, "position", target_pos, REARRANGE_DURATION)
		t.parallel().tween_property(card, "scale", Vector2(PILE_SCALE, PILE_SCALE), REARRANGE_DURATION)
		t.parallel().tween_property(card, "rotation_degrees", 0.0, REARRANGE_DURATION)
	_update_top_card_hover_wiring()


## Only the top card listens for hover-zoom, and only when the pile is face-up
## (showing the discard pile). Face-down piles get no zoom — there's nothing to
## reveal. PASS lets clicks fall through to ClickArea so click-to-open still works.
func _update_top_card_hover_wiring() -> void:
	var visuals := _visuals()
	var zoom_enabled: bool = not face_down
	for i in visuals.size():
		var card := visuals[i]
		var is_top := i == visuals.size() - 1
		if is_top and zoom_enabled:
			card.mouse_filter = Control.MOUSE_FILTER_PASS
			if not card.mouse_entered.is_connected(_on_top_card_hover_entered):
				card.mouse_entered.connect(_on_top_card_hover_entered)
			if not card.mouse_exited.is_connected(_on_top_card_hover_exited):
				card.mouse_exited.connect(_on_top_card_hover_exited)
		else:
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if card.mouse_entered.is_connected(_on_top_card_hover_entered):
				card.mouse_entered.disconnect(_on_top_card_hover_entered)
			if card.mouse_exited.is_connected(_on_top_card_hover_exited):
				card.mouse_exited.disconnect(_on_top_card_hover_exited)


# ── Hover: spread the stack ──────────────────────────────────────────────────

func _on_pile_hover_entered() -> void:
	if _hovered:
		return
	_hovered = true
	_arrange()


func _on_pile_hover_exited() -> void:
	if not _hovered:
		return
	_hovered = false
	_arrange()


# ── Hover: zoom the top card to a clamped full-size preview ──────────────────

func _on_top_card_hover_entered() -> void:
	var visuals := _visuals()
	if visuals.is_empty():
		return
	var top: CardUI = visuals.back()
	_zoomed_top = top
	top.z_index = 100
	var target_local := _zoom_target_position()
	var t: Tween = top.create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	t.tween_property(top, "position", target_local, ZOOM_DURATION)
	t.parallel().tween_property(top, "scale", Vector2.ONE, ZOOM_DURATION)


func _on_top_card_hover_exited() -> void:
	if _zoomed_top == null:
		return
	var leaving := _zoomed_top
	_zoomed_top = null
	leaving.z_index = 0
	var idx := _visuals().find(leaving)
	if idx == -1:
		return
	var slot := _slot_position(idx)
	var t := leaving.create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	t.tween_property(leaving, "position", slot, ZOOM_DURATION)
	t.parallel().tween_property(leaving, "scale", Vector2(PILE_SCALE, PILE_SCALE), ZOOM_DURATION)


## Animate the topmost visual through a peek-flip-return cycle revealing the
## given Card's face. Emits Events.top_card_reveal_finished when complete.
## Used by ravenous_rabble (and any future "reveal top" effect).
func reveal_top(card: Card) -> void:
	var visuals := _visuals()
	if visuals.is_empty():
		Events.top_card_reveal_finished.emit()
		return
	var top: CardUI = visuals.back()
	var slot_pos: Vector2 = top.position
	var slot_scale: Vector2 = top.scale

	var viewport_size: Vector2 = get_viewport_rect().size
	var preview_scale := 1.0
	# Center the visible card on screen (no pivot offset at scale 1.0).
	var visible_top_left_global := (viewport_size - CARD_SIZE_UNSCALED) / 2.0
	var preview_pos := visible_top_left_global - global_position

	top.z_index = 100
	top.card = card

	var t: Tween = top.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Lift + grow.
	t.tween_property(top, "position", preview_pos, 0.20)
	t.parallel().tween_property(top, "scale", Vector2.ONE * preview_scale, 0.20)
	# Flip back → face.
	t.tween_property(top, "scale:x", 0.0, 0.08)
	t.tween_callback(func():
		if is_instance_valid(top) and top.card_render:
			top.card_render.show_back = false)
	t.tween_property(top, "scale:x", preview_scale, 0.08)
	# Hold for the player to read it.
	t.tween_interval(0.6)
	# Flip face → back.
	t.tween_property(top, "scale:x", 0.0, 0.08)
	t.tween_callback(func():
		if is_instance_valid(top) and top.card_render:
			top.card_render.show_back = true)
	t.tween_property(top, "scale:x", preview_scale, 0.08)
	# Return to slot.
	t.tween_property(top, "position", slot_pos, 0.20)
	t.parallel().tween_property(top, "scale", slot_scale, 0.20)
	t.tween_callback(func():
		if is_instance_valid(top):
			top.z_index = 0
		Events.top_card_reveal_finished.emit())


## Compute the local-space position to zoom the top card to, clamped so its
## bounding box stays inside the viewport.
func _zoom_target_position() -> Vector2:
	var visible_size := CARD_SIZE_UNSCALED  # at scale 1.0
	var viewport_size := get_viewport_rect().size
	var panel_global := global_position
	# Ideal: anchored side hugs the screen edge.
	var ideal_global_x: float = panel_global.x
	if anchor_side == SIDE_RIGHT:
		ideal_global_x = panel_global.x + size.x - visible_size.x
	# Anchor the bottom edge of the zoomed card to the bottom of the viewport.
	var ideal_global_y: float = viewport_size.y - visible_size.y
	var clamped_x: float = clampf(ideal_global_x, 0.0, viewport_size.x - visible_size.x)
	var clamped_y: float = clampf(ideal_global_y, 0.0, viewport_size.y - visible_size.y)
	var target_visible_global := Vector2(clamped_x, clamped_y)
	var target_visible_local := target_visible_global - panel_global
	# Convert visible-top-left back to position (scale=1.0 → no pivot adjustment).
	return target_visible_local
