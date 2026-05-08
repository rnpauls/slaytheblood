extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if owner is Player:
		Events.lock_hand.emit()
	Events.card_discarded.connect(_on_card_discarded)
	if await sixloot(owner, 1):
		go_again = true
	else:
		go_again = false
	do_stock_attack_damage_effect(targets, modifiers)
	if owner is Player:
		Events.unlock_hand.emit()
