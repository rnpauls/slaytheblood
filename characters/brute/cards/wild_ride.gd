extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var is_player_owned := owner is Player
	if is_player_owned:
		Events.lock_hand.emit()
	Events.card_discarded.connect(_on_card_discarded)
	go_again = await sixloot(owner, 1)
	do_stock_attack_damage_effect(targets, modifiers)
	if is_player_owned:
		Events.unlock_hand.emit()
