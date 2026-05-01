class_name IntimidatedStatus
extends Status

var intimidated_cards: Array[Card] = []

const INTIMIDATE_MODULATE := Color(0.4, 0.4, 0.6, 0.7)

func initialize_status(target: Node) -> void:
	_pick_and_intimidate(target)

## Called by StatusHandler when stacks increase — pick one more card to intimidate.
func update() -> void:
	pass  # StatusHandler calls initialize_status again on re-add which picks another card

func after_turn_end(side: String, ui: Node) -> void:
	if side == "player":
		ui.queue_free()

func _exit_tree(ui: Node) -> void:
	var target := Status.get_status_owner(ui)
	if not is_instance_valid(target):
		return
	for card in intimidated_cards:
		var card_ui: EnemyCardUI = target.card_ui_map.get(card, null)
		if is_instance_valid(card_ui):
			card_ui.modulate = Color.WHITE
		target.enemy_ai.intimidated_cards.erase(card)
	intimidated_cards.clear()

func _pick_and_intimidate(target: Node) -> void:
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
