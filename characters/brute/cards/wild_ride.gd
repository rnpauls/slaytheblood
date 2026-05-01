extends Card

func apply_effects(targets: Array[Node]) -> void:
	Events.lock_hand.emit()
	Events.card_discarded.connect(_on_card_discarded)
	var player_handler: PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	go_again = await sixloot(player_handler, 1)
	do_stock_attack_damage_effect(targets)
	Events.unlock_hand.emit()
