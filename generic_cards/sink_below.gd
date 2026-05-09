extends Card

func apply_block_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	super.apply_block_effects(targets, _modifiers)
	# NOTE: this call still reaches into BattleUI via group lookup. Pulled out
	# in the planned Phase 6 (Events-based prompt) — keeping the existing
	# behavior here so Phase 2 stays mechanical.
	var card_to_sink: Array[CardUI] = await targets[0].get_tree().get_first_node_in_group("ui_layer").choose_cards_in_hand(1)
	card_to_sink[0].sink()
	if owner and owner.hand_facade:
		owner.hand_facade.draw_cards(1)
