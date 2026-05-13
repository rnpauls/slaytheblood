extends Card

func apply_block_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	super.apply_block_effects(targets, _modifiers)
	if not owner or not owner.hand_facade:
		return
	var chosen: Array[Card] = await owner.hand_facade.prompt_choose_cards(1, "Sink up to 1 card", 0)
	for card in chosen:
		owner.hand_facade.sink_card(card)
		owner.hand_facade.draw_cards(1)
