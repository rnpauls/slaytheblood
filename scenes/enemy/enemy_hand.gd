## Animated card-back fan displayed below each enemy sprite.
## Cards are shown face-down (EnemyCardUI.show_back = true) by default.
## Extends Node2D so it sits cleanly in the Enemy Area2D hierarchy with no
## Control-layout interference — position is set directly in enemy.tscn.
class_name EnemyHand
extends Node2D

const ENEMY_CARD_UI_SCENE := preload("res://scenes/card_ui/enemy_card_ui.tscn")

# ── Fanout settings ───────────────────────────────────────────────────────────
@export var max_width        := 110.0   ## Total spread width of the fan
@export var width_per_card   :=  22.0   ## Per-card contribution to spread
@export var height_offset    :=   8.0   ## Max downward arc at edges (px)
@export var max_rotation_deg :=  18.0   ## Total rotation range (±half at edges)
@export var card_scale       :=   0.35  ## Runtime scale applied to each card

var hovered_card: EnemyCardUI = null

# ── Public API ────────────────────────────────────────────────────────────────

## Instantiate an EnemyCardUI for card, animate it in, and return the new node.
func add_card(card: Card, stats: EnemyStats, modifier_handler: ModifierHandler) -> EnemyCardUI:
	var card_ui := ENEMY_CARD_UI_SCENE.instantiate() as EnemyCardUI
	card_ui.scale    = Vector2.ZERO
	card_ui.modulate = Color(1, 1, 1, 0)
	add_child(card_ui)
	card_ui.setup(card, stats, modifier_handler)

	card_ui.card_hovered.connect(_on_card_hovered)
	card_ui.card_unhovered.connect(_on_card_unhovered)

	_arrange_cards()

	# Draw animation
	var t := card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card_ui, "scale",    Vector2.ONE * card_scale, 0.2)
	t.parallel().tween_property(card_ui, "modulate", Color.WHITE,   0.2)

	return card_ui

## Animate a card out of the hand and free it.
func remove_card(card_ui: EnemyCardUI) -> void:
	if not is_instance_valid(card_ui):
		return
	if hovered_card == card_ui:
		hovered_card = null

	var t := card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(card_ui, "scale",    Vector2.ZERO,           0.15)
	t.parallel().tween_property(card_ui, "modulate", Color(1,1,1,0), 0.15)
	t.tween_callback(card_ui.queue_free)
	_arrange_cards()

## Remove all cards instantly (e.g. on enemy death).
func clear_cards() -> void:
	for child in get_children():
		child.queue_free()
	hovered_card = null

# ── Fanout layout ─────────────────────────────────────────────────────────────

func _arrange_cards() -> void:
	var cards: Array[EnemyCardUI] = []
	for child in get_children():
		# Skip cards that are currently staged (z_as_relative=false means they've
		# been lifted out of the normal hand layout by EnemyStagedDisplay).
		if child is EnemyCardUI and (child as CanvasItem).z_as_relative:
			cards.append(child)

	if cards.is_empty():
		return

	var count      := cards.size()
	var base_width := minf(count * width_per_card, max_width)

	var hovered_index := -1
	if hovered_card != null:
		hovered_index = cards.find(hovered_card)

	for i in count:
		var card := cards[i]
		if card == hovered_card:
			continue

		var eff_t: float = 0.5 if count == 1 else float(i) / float(count - 1)

		# Spread neighbours away from hovered card
		if hovered_card != null and hovered_index != -1:
			var raw_t  := float(i) / float(count - 1)
			var dist   := absf(i - hovered_index) / float(max(1, count))
			var push   := (1.0 - dist) * 0.08
			if i < hovered_index:
				eff_t = raw_t - push
			elif i > hovered_index:
				eff_t = raw_t + push
			eff_t = clampf(eff_t, 0.0, 1.0)

		# cx = horizontal center of this card's top-center in EnemyHand local space
		var cx: float  = lerp(-base_width * 0.5, base_width * 0.5, eff_t)
		# Arc: edges dip DOWN, center stays at 0  →  4*(t-0.5)^2 peaks at edges
		var cy: float  = 4.0 * (eff_t - 0.5) * (eff_t - 0.5) * height_offset
		# Rotation: left edge tilts left (negative), right edge tilts right (positive)
		var rot: float = (eff_t - 0.5) * max_rotation_deg

		# Cards are Control nodes; their global_position is their top-left corner in
		# screen space. We want the visual top-center (pivot_offset.x=100 at scale) to
		# sit at (cx, cy) relative to EnemyHand's global origin, so:
		#   top-left global x = hand_global.x + cx - 100*card_scale
		#   top-left global y = hand_global.y + cy
		var hand_global := global_position
		var gpos := hand_global + Vector2(cx - 100.0 * card_scale, cy)
		card.animate_to_global_position_and_rotation_and_scale(gpos, rot, card_scale, 0.2)

	# Hovered card: keep its current x, raise it upward, and scale up slightly.
	# We read global_position.x from the card itself so it stays in column — no x drift.
	if hovered_card != null and hovered_card in cards:
		var hgpos := Vector2(hovered_card.global_position.x, global_position.y - 12.0)
		hovered_card.animate_to_global_position_and_rotation_and_scale(
			hgpos, 0.0, card_scale * 1.15, 0.15
		)

# ── Hover callbacks ───────────────────────────────────────────────────────────

func _on_card_hovered(card: EnemyCardUI) -> void:
	hovered_card = card
	_arrange_cards()

func _on_card_unhovered(card: EnemyCardUI) -> void:
	if hovered_card == card:
		hovered_card = null
		_arrange_cards()
