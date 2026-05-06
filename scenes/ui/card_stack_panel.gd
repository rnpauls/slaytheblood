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

@export var card_pile: CardPile : set = set_card_pile
## When true, new visuals show the card-back; when false, the face is visible.
@export var face_down: bool = true
## When true, an incoming card lands at the BACK of the visible stack (north,
## peeked from above) instead of the front. Use for the draw pile, where a
## pitched/sunk card goes to the bottom of the conceptual deck. Discard piles
## leave this false so the most-recently-discarded card sits on top.
@export var add_to_back_of_deck: bool = false

@onready var click_area: Button = %ClickArea
@onready var counter: Label = %Counter

var _hovered: bool = false


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


## Accept an existing CardUI as a new member of the stack. Caller should call
## this BEFORE mutating the resource pile via add_card(). The card_ui keeps its
## current global transform (no visual jump on reparent) and tweens to its slot.
## When add_to_back_of_deck is true (draw pile), the new card sinks to the BACK
## of the visible stack (peeked from the north) instead of becoming the new top.
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
	# Discard pile: last child = south (most-visible) → new card on top.
	# Draw pile: first child = north (peeked) → pitched card slides under the rest.
	if add_to_back_of_deck:
		move_child(card_ui, 0)
	else:
		move_child(card_ui, get_child_count() - 1)
	# Reset pivot to the card's center: the drag interaction (card_base_state)
	# rewrites pivot_offset to the click point so the card grabs from there, but
	# _slot_position assumes pivot == CARD_PIVOT when converting visible-top-left
	# to position. Without this, played cards land with a horizontal offset in
	# the column (block/pitch don't hit that code path so they look fine).
	card_ui.pivot_offset = CARD_PIVOT
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
		card_ui.card_render.set_glow(false)
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
## column (most-south). For discard piles the most-recently-added card is the
## last child — fully visible, with older cards peeking above it. For draw piles
## (add_to_back_of_deck=true) the most-recently-added card is instead the first
## child, so a freshly pitched card peeks from the north and the next-to-draw
## card stays on the visible bottom.
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
	_update_click_area(n)
	if n == 0:
		return
	for i in n:
		var card := visuals[i]
		var target_pos := _slot_position(i)
		# Kill any in-flight tween on this card so a stale tween from the previous
		# arrange (e.g. one started by accept_incoming_visual ~150ms before the
		# resource size_changed handler re-runs arrange) doesn't fight the new one
		# on the same position/scale/rotation properties.
		if card.tween and card.tween.is_running():
			card.tween.kill()
		card.tween = card.create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		card.tween.tween_property(card, "position", target_pos, REARRANGE_DURATION)
		card.tween.parallel().tween_property(card, "scale", Vector2(PILE_SCALE, PILE_SCALE), REARRANGE_DURATION)
		card.tween.parallel().tween_property(card, "rotation_degrees", 0.0, REARRANGE_DURATION)


## Shrink the click/hover region to just the visible card stack, so hovering the
## empty space above the cards (the panel extends taller than the cards' actual
## peek-out region) doesn't register as a pile hover. The ClickArea is anchored
## to the panel's bottom edge (anchor_top = anchor_bottom = 1.0), so a negative
## offset_top sets its height in pixels above the panel bottom.
func _update_click_area(n: int) -> void:
	if not click_area:
		return
	if n == 0:
		click_area.offset_top = 0.0
		return
	# Slot 0 is the topmost (north) card. _slot_position returns Control.position;
	# the visible top edge sits pivot_y * (1 - scale) below that.
	var topmost_visible_y: float = _slot_position(0).y + (1.0 - PILE_SCALE) * CARD_PIVOT.y
	click_area.offset_top = topmost_visible_y - size.y


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
