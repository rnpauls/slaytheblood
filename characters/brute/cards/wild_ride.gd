extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	Events.lock_hand.emit()
	Events.card_discarded.connect(_on_card_discarded)
	#var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	var player_handler: PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	if sixloot(player_handler, 1):
		go_again = true
	else:
		go_again = false
	do_stock_attack_damage_effect(targets, modifiers)
	Events.unlock_hand.emit()
