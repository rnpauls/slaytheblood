class_name IntimidatedStatus
extends Status

## Cards this status has intimidated on the enemy. One per stack.
var intimidated_cards: Array[Card] = []

## Modulate applied to an EnemyCardUI to signal the intimidated state.
const INTIMIDATE_MODULATE := Color(0.4, 0.4, 0.6, 0.7)

var _target_ref: Node = null
var _bound_apply: Callable

func initialize_status(target: Node) -> void:
	_target_ref = target
	_pick_and_intimidate(target)
	_bound_apply = apply_status.bind(target)
	Events.player_turn_ended.connect(_bound_apply)


func apply_status(target: Node) -> void:
	status_applied.emit(self)


## Called by StatusHandler when a second intimidated status is added (INTENSITY stacking).
## Picks one additional card to intimidate.
func update() -> void:
	if _target_ref:
		_pick_and_intimidate(_target_ref)


func _pick_and_intimidate(target: Node) -> void:
	# Only pick from cards not already intimidated.
	var available: Array = target.hand.filter(
		func(c: Card) -> bool: return not c in intimidated_cards
	)
	if available.is_empty():
		return

	var card: Card = available[randi() % available.size()]
	intimidated_cards.append(card)
	target.enemy_ai.intimidated_cards.append(card)

	var card_ui: EnemyCardUI = target.card_ui_map.get(card, null)
	if is_instance_valid(card_ui):
		card_ui.modulate = INTIMIDATE_MODULATE


func _exit_tree() -> void:
	if _bound_apply and Events.player_turn_ended.is_connected(_bound_apply):
		Events.player_turn_ended.disconnect(_bound_apply)

	if not is_instance_valid(_target_ref):
		return

	# Restore visuals and clear AI references for all intimidated cards.
	for card in intimidated_cards:
		var card_ui: EnemyCardUI = _target_ref.card_ui_map.get(card, null)
		if is_instance_valid(card_ui):
			card_ui.modulate = Color.WHITE
		_target_ref.enemy_ai.intimidated_cards.erase(card)

	intimidated_cards.clear()
