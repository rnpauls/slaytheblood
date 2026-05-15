## Per-enemy "played cards" column displayed to the right of the sprite.
## Accumulates EnemyCardUIs played during the enemy's turn (instead of burning
## each one immediately) so the player can review what was played. At EOT the
## battle phase calls burn_all() to shader-dissolve every card in parallel.
##
## Layout mirrors the player's CardStackPanel: cards stack vertically, the most
## recent play sits fully visible at the bottom, older plays peek above. Per-card
## hover (similar to EnemyStagedDisplay) pops the hovered card up to full scale
## with a top-bar clamp so it never slides under the HUD.
class_name EnemyPlayedCardsDisplay
extends Node2D

## Must match CardUI.tscn's pivot_offset (200x280 card, centered pivot).
const CARD_PIVOT_OFFSET := Vector2(100, 140)

@export var card_scale         := 0.4
@export var hovered_scale      := 1.0
## Total vertical span used by older-card peeks. The bottom card sits at the
## display's origin; older cards stack upward, sharing this height budget.
@export var max_peek_height    := 60.0
## Per-step clamp so a 2-card stack doesn't have a giant gap.
@export var max_per_card_peek  := 24.0
## How far left a hovered card juts out so it reads as "popped out" of the column.
@export var hover_x_offset     := 40.0

var _cards: Array[EnemyCardUI] = []
var _hovered_card: EnemyCardUI = null


# ── Public API ────────────────────────────────────────────────────────────────

func add_card(card_ui: EnemyCardUI) -> void:
	if not is_instance_valid(card_ui):
		return
	_cards.append(card_ui)
	if card_ui.get_parent() != self:
		card_ui.reparent(self)
	card_ui.z_index = 0
	card_ui.z_as_relative = true
	# Some upstream paths (CardStackPanel handoff) set MOUSE_FILTER_IGNORE on
	# the card and its descendants. Reset so per-card hover fires here.
	card_ui.mouse_filter = Control.MOUSE_FILTER_STOP

	if not card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.connect(_on_card_hovered)
	if not card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.connect(_on_card_unhovered)

	_arrange_cards(Constants.TWEEN_CARD_STAGE)


func burn_all() -> void:
	if _cards.is_empty():
		return
	var burning: Array[EnemyCardUI] = _cards.duplicate()
	_cards.clear()
	_hovered_card = null

	for card_ui in burning:
		if not is_instance_valid(card_ui):
			continue
		_disconnect_hover(card_ui)

	for card_ui in burning:
		if is_instance_valid(card_ui):
			card_ui._burn_up()

	await get_tree().create_timer(CardUI.BURN_DURATION + 0.05).timeout

	for card_ui in burning:
		if is_instance_valid(card_ui):
			card_ui.queue_free()


func is_empty() -> bool:
	return _cards.is_empty()


# ── Layout ────────────────────────────────────────────────────────────────────

func _arrange_cards(duration: float) -> void:
	var count := _cards.size()
	if count == 0:
		return

	var per_card_peek: float = 0.0
	if count > 1:
		per_card_peek = minf(max_per_card_peek, max_peek_height / float(count - 1))

	for i in count:
		var card_ui := _cards[i]
		if not is_instance_valid(card_ui):
			continue
		var step: int = count - 1 - i
		var is_hovered: bool = card_ui == _hovered_card
		var s: float = hovered_scale if is_hovered else card_scale
		var base_y: float = -CARD_PIVOT_OFFSET.y - float(step) * per_card_peek
		var target: Vector2 = _scale_target(s, base_y)
		if is_hovered:
			target.x -= hover_x_offset
		card_ui.animate_to_local_position_and_rotation_and_scale(
			target, 0.0, s, duration
		)


## Pivot-anchored local target for a given scale at `base_y` (already accounts
## for the card pivot). When the resulting top edge would slip under the HUD
## TopBar, push the card down by the shortfall — mirrors the clamp pattern in
## EnemyStagedDisplay._scale_target.
func _scale_target(s: float, base_y: float) -> Vector2:
	var top_edge_global_y := global_position.y + base_y + CARD_PIVOT_OFFSET.y - CARD_PIVOT_OFFSET.y * s
	# top_edge_global_y above simplifies to global_position.y + base_y + CARD_PIVOT_OFFSET.y * (1 - s).
	var clamp_push := maxf(0.0, Constants.TOP_BAR_HEIGHT - top_edge_global_y)
	return Vector2(-CARD_PIVOT_OFFSET.x, base_y + clamp_push)


# ── Hover ─────────────────────────────────────────────────────────────────────

func _on_card_hovered(card: EnemyCardUI) -> void:
	if not is_instance_valid(card) or _hovered_card == card:
		return
	_hovered_card = card
	# Draw on top of neighbors.
	move_child(card, get_child_count() - 1)
	_arrange_cards(Constants.TWEEN_FADE)


func _on_card_unhovered(card: EnemyCardUI) -> void:
	if _hovered_card != card:
		return
	_hovered_card = null
	_arrange_cards(Constants.TWEEN_FADE)


func _disconnect_hover(card_ui: EnemyCardUI) -> void:
	if card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.disconnect(_on_card_hovered)
	if card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.disconnect(_on_card_unhovered)
