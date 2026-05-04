class_name IntimidatedStatus
extends Status

## Cards this status has intimidated. One per stack.
var intimidated_cards: Array[Card] = []

## Modulate applied to a card UI to signal the intimidated state.
const INTIMIDATE_MODULATE := Color(0.4, 0.4, 0.6, 0.7)

var _target_ref: Node = null
var _bound_apply: Callable

## Tracks the card UI nodes directly so we can restore modulate even after
## card_ui_map has been cleared (e.g. the card was staged before status expired).
var _intimidated_uis: Array[CardUI] = []

func initialize_status(target: Node) -> void:
	_target_ref = target
	_pick_and_intimidate(target)
	_bound_apply = apply_status.bind(target)
	if target is Enemy:
		Events.player_turn_ended.connect(_bound_apply)
	else:
		Events.enemy_phase_ended.connect(_bound_apply)


func apply_status(target: Node) -> void:
	status_applied.emit(self)


## Called by StatusHandler when a second intimidated status is added (INTENSITY stacking).
## Picks one additional card to intimidate.
func update() -> void:
	if _target_ref:
		_pick_and_intimidate(_target_ref)


func _pick_and_intimidate(target: Node) -> void:
	# Build available list from cards not already intimidated.
	var all_cards: Array = []
	if target is Enemy:
		all_cards = target.hand
	else:
		var hand_node: Hand = target.get_tree().get_first_node_in_group("player_hand")
		if hand_node:
			for child in hand_node.get_children():
				if child is PlayerCardUI:
					all_cards.append(child.card)

	var available: Array = all_cards.filter(
		func(c: Card) -> bool: return not c in intimidated_cards
	)
	if available.is_empty():
		return

	var card: Card = available[randi() % available.size()]
	intimidated_cards.append(card)

	if target is Enemy:
		target.enemy_ai.intimidated_cards.append(card)
		var card_ui: CardUI = target.card_ui_map.get(card, null)
		if is_instance_valid(card_ui):
			card_ui.modulate = INTIMIDATE_MODULATE
			_intimidated_uis.append(card_ui)
	else:
		target.intimidated_cards.append(card)
		# Tint the matching PlayerCardUI in the hand.
		var hand_node: Hand = target.get_tree().get_first_node_in_group("player_hand")
		if hand_node:
			for child in hand_node.get_children():
				if child is PlayerCardUI and child.card == card:
					child.modulate = INTIMIDATE_MODULATE
					_intimidated_uis.append(child)
					break


func _exit_tree() -> void:
	if _bound_apply:
		if _target_ref is Enemy:
			if Events.player_turn_ended.is_connected(_bound_apply):
				Events.player_turn_ended.disconnect(_bound_apply)
		else:
			if Events.enemy_phase_ended.is_connected(_bound_apply):
				Events.enemy_phase_ended.disconnect(_bound_apply)

	# Restore visuals using the directly-tracked UI nodes (safe even if card_ui_map was cleared).
	for card_ui in _intimidated_uis:
		if is_instance_valid(card_ui):
			card_ui.modulate = Color.WHITE
	_intimidated_uis.clear()

	if not is_instance_valid(_target_ref):
		intimidated_cards.clear()
		return

	# Clear the AI / player blocker lists.
	for card in intimidated_cards:
		if _target_ref is Enemy:
			_target_ref.enemy_ai.intimidated_cards.erase(card)
		else:
			_target_ref.intimidated_cards.erase(card)

	intimidated_cards.clear()
