extends Card

func apply_block_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	super.apply_block_effects(targets, _modifiers)
	var card_to_sink: Array[CardUI]
	#var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	card_to_sink = await targets[0].get_tree().get_first_node_in_group("ui_layer").choose_cards_in_hand(1)
	card_to_sink[0].sink()
	targets[0].get_tree().get_first_node_in_group("player_handler").draw_card()
	return 
