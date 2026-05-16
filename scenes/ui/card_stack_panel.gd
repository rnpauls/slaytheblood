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

# Default visible scale of cards while in the pile. Kept as a const so external
# callers (battle_ui.gd) can reference it without needing a panel instance.
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
## Per-instance visible scale of cards in the pile. Defaults to PILE_SCALE so
## existing draw/discard piles render unchanged; smaller piles (e.g. per-enemy
## exhaust pile) override this to render a tighter stack.
@export var pile_scale: float = PILE_SCALE
## Cap on how many visual CardUIs the pile shows. 0 means unlimited (default,
## matches the player's draw/discard piles which always mirror the resource).
## When set, the oldest peeking visual (front child / north) is evicted as new
## cards arrive past the cap. The underlying resource pile is unaffected — the
## CardPileView opened on click still shows every card.
@export var max_visible_cards: int = 0
## Total vertical span (px) of the stack peek when the pile is NOT hovered.
## Per-card offset scales as max_peek_height / (n - 1), clamped by max_per_card.
@export var max_peek_height: float = 50.0
## Per-card offset cap (px) when not hovered.
@export var max_per_card_peek: float = 20.0
## Total vertical span (px) of the stack peek when the pile IS hovered (spreads
## the stack open so the player can read more of each card).
@export var hover_peek_height: float = 70.0
## Per-card offset cap (px) when hovered.
@export var hover_per_card_peek: float = 30.0

## Where the Counter label sits relative to the pile. Each case overwrites the
## Counter's anchors + offsets in _ready (the Counter values baked into
## card_stack_panel.tscn become irrelevant once a placement is applied).
##   CENTER_BOTTOM — centered below the cards (legacy default)
##   RIGHT_OF_PILE — to the right of the pile (player draw pile)
##   LEFT_OF_PILE  — to the left of the pile (player discard pile)
##   BELOW_PILE    — below the pile, past the south card (enemy exhaust pile)
enum CounterPlacement {
	CENTER_BOTTOM,
	RIGHT_OF_PILE,
	LEFT_OF_PILE,
	BELOW_PILE,
}
@export var counter_placement: CounterPlacement = CounterPlacement.CENTER_BOTTOM : set = _set_counter_placement

@onready var click_area: Button = %ClickArea
@onready var counter: Label = %Counter

var _hovered: bool = false
# A pitched card flying in via accept_pitched_visual gets its own continuous
# tween (diagonal slide with smooth scale/rotation). _arrange skips it so the
# size_changed-driven re-arrange doesn't kill the in-flight tween mid-flight.
var _pitched_in_flight: CardUI = null


func _ready() -> void:
	click_area.mouse_entered.connect(_on_pile_hover_entered)
	click_area.mouse_exited.connect(_on_pile_hover_exited)
	click_area.pressed.connect(func(): pressed.emit())
	_apply_counter_placement()


func _set_counter_placement(value: CounterPlacement) -> void:
	counter_placement = value
	if is_node_ready():
		_apply_counter_placement()


## Position the Counter label per the chosen placement. All presets pin a
## single anchor point (anchor_left == anchor_right, anchor_top == anchor_bottom)
## and use offsets to define the label rect; this avoids stretching when the
## parent panel resizes.
func _apply_counter_placement() -> void:
	if not counter:
		return
	match counter_placement:
		CounterPlacement.CENTER_BOTTOM:
			counter.anchor_left = 0.5
			counter.anchor_right = 0.5
			counter.anchor_top = 1.0
			counter.anchor_bottom = 1.0
			counter.offset_left = -28.0
			counter.offset_right = 28.0
			counter.offset_top = -36.0
			counter.offset_bottom = 0.0
		CounterPlacement.RIGHT_OF_PILE:
			# Anchored at the panel's bottom-right corner; label sits just
			# outside the right edge, vertically near the bottom (close to
			# the screen edge for the player's bottom-left draw pile).
			counter.anchor_left = 1.0
			counter.anchor_right = 1.0
			counter.anchor_top = 1.0
			counter.anchor_bottom = 1.0
			counter.offset_left = -16
			counter.offset_right = 40
			counter.offset_top = -20.0
			counter.offset_bottom = 16.0
		CounterPlacement.LEFT_OF_PILE:
			# Mirror of RIGHT_OF_PILE — anchored at the bottom-left corner;
			# label sits just outside the left edge (player's bottom-right
			# discard pile).
			counter.anchor_left = 0.0
			counter.anchor_right = 0.0
			counter.anchor_top = 1.0
			counter.anchor_bottom = 1.0
			counter.offset_left = -40.0
			counter.offset_right = 16.0
			counter.offset_top = -20.0
			counter.offset_bottom = 16.0
		CounterPlacement.BELOW_PILE:
			# Centered horizontally on the panel, positioned below the
			# panel rect — past the south card for piles whose cards extend
			# below the panel (small pile_scale; e.g. enemy exhaust).
			counter.anchor_left = 0.5
			counter.anchor_right = 0.5
			counter.anchor_top = 1.0
			counter.anchor_bottom = 1.0
			counter.offset_left = -63.0
			counter.offset_right = -7.0
			counter.offset_top = 57.0
			counter.offset_bottom = 93.0


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
	card_ui.scale = Vector2(pile_scale, pile_scale)
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# CardRenderContainer and its descendants default to MOUSE_FILTER_STOP and would
	# otherwise capture hover events before they reach the panel's ClickArea sibling.
	_set_descendants_mouse_filter(card_ui, Control.MOUSE_FILTER_IGNORE)
	card_ui.z_index = 0
	if card_ui.card_render:
		card_ui.card_render.show_back = face_down
		card_ui.card_render.set_glow(false)
	_enforce_max_visible()
	_arrange()


func _set_descendants_mouse_filter(node: Node, filter: int) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = filter
		_set_descendants_mouse_filter(child, filter)


## Pitched-card variant of accept_incoming_visual. Reparents the card and
## tweens it directly from its current global transform (hand position, full
## scale, any rotation) to the top-of-stack slot in one continuous motion —
## no x-snap, no instant scale snap. The diagonal slide reads as a clean arc
## from hand to discard top, instead of the teleport-then-slide that
## accept_incoming_visual produces (intentional for multi-card discards but
## ugly for a single pitched card).
func accept_pitched_visual(card_ui: CardUI) -> void:
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()
	var gpos: Vector2 = card_ui.global_position
	var gscale: Vector2 = card_ui.scale
	var grot: float = card_ui.rotation_degrees
	var prev_parent: Node = card_ui.get_parent()
	if prev_parent:
		prev_parent.remove_child(card_ui)
	add_child(card_ui)
	# Discard pile (add_to_back_of_deck=false) → last child = visible top.
	move_child(card_ui, get_child_count() - 1)
	card_ui.pivot_offset = CARD_PIVOT
	# Restore original global transform so the card visibly starts where the
	# user dragged/clicked it from. NO x-snap, NO scale/rotation snap —
	# everything tweens together.
	card_ui.global_position = gpos
	card_ui.scale = gscale
	card_ui.rotation_degrees = grot
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_descendants_mouse_filter(card_ui, Control.MOUSE_FILTER_IGNORE)
	card_ui.z_index = 1
	if card_ui.card_render:
		card_ui.card_render.show_back = face_down
		card_ui.card_render.set_glow(false)

	_pitched_in_flight = card_ui
	# Evict over-cap visuals BEFORE computing the target slot so target_index
	# reflects the post-eviction count.
	_enforce_max_visible()
	# The card is now the last visual child; _slot_position uses _visuals().size().
	var target_index: int = _visuals().size() - 1
	var target_pos: Vector2 = _slot_position(target_index)
	# Slightly longer than REARRANGE_DURATION for emphasis. TRANS_CUBIC.EASE_OUT
	# decelerates smoothly into the slot. A tiny scale "settle" via TRANS_BACK
	# adds a satisfying pop on landing without overshooting position.
	var fly_duration := 0.32
	var t := card_ui.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card_ui, "position", target_pos, fly_duration)
	t.tween_property(card_ui, "rotation_degrees", 0.0, fly_duration)
	t.tween_property(card_ui, "scale", Vector2(pile_scale, pile_scale), fly_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(func():
		if _pitched_in_flight == card_ui:
			_pitched_in_flight = null
		card_ui.z_index = 0
	)
	card_ui.tween = t

	# Rearrange the other cards in the pile to make room (their slots shift
	# slightly). _arrange skips _pitched_in_flight so the in-flight tween isn't
	# killed and restarted with the standard ease.
	_arrange()
	_update_counter()


## Spawn a fresh CardUI at `source_global_pos` (face-up, full size) and tween
## it into this pile after a brief readability hold. Used by CardAddEffect via
## the BattleUI router to show "card X was added to your draw/discard pile".
##
## Caller must invoke this BEFORE mutating the resource pile (same handoff
## invariant as accept_pitched_visual): the new CardUI is parented in
## immediately, so when the resource size_changed handler runs it sees matching
## visual/resource counts and skips its own auto-spawn.
##
## For face-down piles (draw pile), the card flips back-side at the end of the
## flight so the player sees what was added during the flight, then it joins
## the deck face-down.
func animate_card_in(card_resource: Card, source_global_pos: Vector2) -> void:
	var visual := CARD_UI_SCENE.instantiate() as CardUI
	add_child(visual)
	visual.card = card_resource
	# add_to_back_of_deck=true (draw pile) puts the new card at the front
	# (north / peeked) child slot; discard pile puts it at the back (visible top).
	if add_to_back_of_deck:
		move_child(visual, 0)
	else:
		move_child(visual, get_child_count() - 1)
	visual.pivot_offset = CARD_PIVOT
	visual.global_position = source_global_pos
	visual.scale = Vector2.ONE
	visual.rotation_degrees = 0.0
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_descendants_mouse_filter(visual, Control.MOUSE_FILTER_IGNORE)
	visual.z_index = 10
	if visual.card_render:
		visual.card_render.show_back = false
		visual.card_render.set_glow(false)

	_pitched_in_flight = visual
	# Evict over-cap visuals BEFORE computing the target slot.
	_enforce_max_visible()

	var target_index: int = 0 if add_to_back_of_deck else _visuals().size() - 1
	var target_pos: Vector2 = _slot_position(target_index)
	var hold_duration := 0.3
	var fly_duration := 0.4

	var t := visual.create_tween()
	t.tween_interval(hold_duration)
	t.tween_property(visual, "position", target_pos, fly_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "rotation_degrees", 0.0, fly_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "scale", Vector2(pile_scale, pile_scale), fly_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Face-down piles: flip the card to its back as it lands so it joins the
	# deck visually consistent with the rest of the stack.
	if face_down:
		t.tween_property(visual.card_render, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP_FAST)
		t.tween_callback(func():
			if is_instance_valid(visual) and visual.card_render:
				visual.card_render.show_back = true)
		t.tween_property(visual.card_render, "scale:x", 1.0, Constants.TWEEN_CARD_FLIP_FAST)

	t.tween_callback(func():
		if _pitched_in_flight == visual:
			_pitched_in_flight = null
		if is_instance_valid(visual):
			visual.z_index = 0)
	visual.tween = t

	_arrange()
	_update_counter()


# ── Internal: spawn/free to match resource size ───────────────────────────────

func _on_pile_size_changed(_new_size: int) -> void:
	_sync_to_resource()


func _sync_to_resource() -> void:
	if not card_pile:
		return
	var visuals := _visuals()
	# When capped, only ever spawn up to max_visible_cards visuals — the extras
	# live only in the resource pile and surface via the CardPileView on click.
	var target: int = card_pile.cards.size()
	if max_visible_cards > 0:
		target = min(target, max_visible_cards)
	var diff := target - visuals.size()
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
	# Defensive in case max_visible_cards was lowered at runtime, or a handoff
	# pushed visuals past the cap.
	_enforce_max_visible()
	_update_counter()
	_arrange()


## Evict the oldest peeking visuals (front children = slot 0 = north) when the
## visual count exceeds max_visible_cards. No-op if the cap is unlimited (0).
## remove_child + queue_free both run so _visuals() reflects the eviction this
## frame (queue_free alone is deferred to end-of-frame).
func _enforce_max_visible() -> void:
	if max_visible_cards <= 0:
		return
	var visuals := _visuals()
	while visuals.size() > max_visible_cards:
		var oldest: CardUI = visuals[0]
		if _pitched_in_flight == oldest:
			_pitched_in_flight = null
		if oldest.tween and oldest.tween.is_running():
			oldest.tween.kill()
		if oldest.get_parent():
			oldest.get_parent().remove_child(oldest)
		oldest.queue_free()
		visuals = _visuals()


func _spawn_back() -> void:
	var visual := CARD_UI_SCENE.instantiate() as CardUI
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	# scene `ready` runs on add_child; show_back's await ready resolves immediately.
	visual.card_render.show_back = face_down
	_set_descendants_mouse_filter(visual, Control.MOUSE_FILTER_IGNORE)
	# Spawn off-screen below; _arrange will tween it into place.
	visual.position = _slot_position(0) + Vector2(0, 200)
	visual.scale = Vector2(pile_scale, pile_scale)


func _update_counter() -> void:
	if not counter:
		return
	var n: int = card_pile.cards.size() if card_pile else 0
	counter.text = str(n)
	# Hide the label entirely when the pile is empty — an idle "0" reads as
	# noise next to a visibly empty pile.
	counter.visible = n > 0


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
	var max_height: float = hover_peek_height if _hovered else max_peek_height
	var max_per_card: float = hover_per_card_peek if _hovered else max_per_card_peek
	var per_card_offset: float = 0.0
	if n > 1:
		per_card_offset = minf(max_per_card, max_height / float(n - 1))
	var card_height_visible: float = CARD_SIZE_UNSCALED.y * pile_scale
	var top_visible_band: float = TOP_VISIBLE_FRAC * card_height_visible
	var bottom_top_y: float = size.y - top_visible_band
	var step: int = n - 1 - i
	var visible_top_y: float = bottom_top_y - step * per_card_offset
	# Convert visible-top-left to Control.position by subtracting the pivot offset
	# induced by Control scaling around pivot_offset.
	var visible_top_left := Vector2(0, visible_top_y)
	return visible_top_left - (1.0 - pile_scale) * CARD_PIVOT


func _arrange() -> void:
	var visuals := _visuals()
	var n := visuals.size()
	_update_click_area(n)
	if n == 0:
		return
	for i in n:
		var card := visuals[i]
		# A pitched card flying in via accept_pitched_visual owns its own tween
		# to the slot; skip it so we don't override the smooth diagonal motion.
		if card == _pitched_in_flight:
			continue
		var target_pos := _slot_position(i)
		# Kill any in-flight tween on this card so a stale tween from the previous
		# arrange (e.g. one started by accept_incoming_visual ~150ms before the
		# resource size_changed handler re-runs arrange) doesn't fight the new one
		# on the same position/scale/rotation properties.
		if card.tween and card.tween.is_running():
			card.tween.kill()
		card.tween = card.create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		card.tween.tween_property(card, "position", target_pos, REARRANGE_DURATION)
		card.tween.parallel().tween_property(card, "scale", Vector2(pile_scale, pile_scale), REARRANGE_DURATION)
		card.tween.parallel().tween_property(card, "rotation_degrees", 0.0, REARRANGE_DURATION)


## Shrink the click/hover region to just the visible card stack, so hovering
## either the empty space above the cards (the panel extends taller than the
## cards' actual peek-out region) or the empty space to the right of a small
## stack (panel width may exceed card width when pile_scale is small) doesn't
## register as a pile hover.
##
## The ClickArea is anchored at all four sides to the panel rect (offsets adjust
## inset/outset from that rect). Vertically, the click region extends from the
## topmost peeking card's visible top to the bottommost card's visible bottom —
## which can lie BELOW the panel rect for small pile_scale (positive
## offset_bottom). Horizontally, the click region is the card-visible width
## starting from the panel's left edge.
func _update_click_area(n: int) -> void:
	if not click_area:
		return
	if n == 0:
		click_area.offset_top = 0.0
		click_area.offset_bottom = 0.0
		click_area.offset_left = 0.0
		click_area.offset_right = 0.0
		return
	# Slot 0 is the topmost (north) card. _slot_position returns Control.position;
	# the visible top edge sits pivot_y * (1 - scale) below that.
	var topmost_visible_y: float = _slot_position(0).y + (1.0 - pile_scale) * CARD_PIVOT.y
	click_area.offset_top = topmost_visible_y - size.y
	# Bottom card's visible bottom = (size.y - top_visible_band) + card_height_visible.
	# That can exceed size.y when pile_scale is small; offset_bottom positive
	# extends the click area below the panel rect to cover those visible cards.
	var card_height_visible: float = CARD_SIZE_UNSCALED.y * pile_scale
	var top_visible_band: float = TOP_VISIBLE_FRAC * card_height_visible
	var bottommost_visible_y: float = (size.y - top_visible_band) + card_height_visible
	click_area.offset_bottom = bottommost_visible_y - size.y
	# Width: visible cards start at panel-local x=0 (see _slot_position math) and
	# span CARD_SIZE_UNSCALED.x * pile_scale to the right. Trim the right edge so
	# the click area doesn't include empty space when panel is wider than card.
	var card_width_visible: float = CARD_SIZE_UNSCALED.x * pile_scale
	click_area.offset_left = 0.0
	click_area.offset_right = card_width_visible - size.x


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


## Move every visual CardUI from this panel into target panel, reusing the
## existing accept_incoming_visual handoff. The caller is responsible for the
## resource-side mutation immediately after, mirroring the standard handoff
## invariant: visuals first, resources second, so the size_changed handlers
## see matching counts on both panels and skip auto-spawn/free.
##
## accept_incoming_visual sets show_back = target.face_down on accept, so cards
## flying from the (face-up) discard pile to the (face-down) draw pile flip to
## face-down as part of the handoff. The arrange tween provides the slide.
func reshuffle_to(target: CardStackPanel) -> void:
	# _visuals() returns children in order; iterate as-is so the visual that
	# was on top of the discard ends up at the back of the draw stack.
	var visuals := _visuals()
	for v in visuals:
		target.accept_incoming_visual(v)
	_update_counter()


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
	t.tween_property(top, "position", preview_pos, Constants.TWEEN_PANEL_SLIDE)
	t.parallel().tween_property(top, "scale", Vector2.ONE * preview_scale, Constants.TWEEN_PANEL_SLIDE)
	# Flip back → face.
	t.tween_property(top, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP_FAST)
	t.tween_callback(func():
		if is_instance_valid(top) and top.card_render:
			top.card_render.show_back = false)
	t.tween_property(top, "scale:x", preview_scale, Constants.TWEEN_CARD_FLIP_FAST)
	# Hold for the player to read it.
	t.tween_interval(0.6)
	# Flip face → back.
	t.tween_property(top, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP_FAST)
	t.tween_callback(func():
		if is_instance_valid(top) and top.card_render:
			top.card_render.show_back = true)
	t.tween_property(top, "scale:x", preview_scale, Constants.TWEEN_CARD_FLIP_FAST)
	# Return to slot.
	t.tween_property(top, "position", slot_pos, Constants.TWEEN_PANEL_SLIDE)
	t.parallel().tween_property(top, "scale", slot_scale, Constants.TWEEN_PANEL_SLIDE)
	t.tween_callback(func():
		if is_instance_valid(top):
			top.z_index = 0
		Events.top_card_reveal_finished.emit())
