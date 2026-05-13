extends Card


# Flicker Step is player-only by design — the prompt UI has no enemy
# equivalent. EnemyHandFacade.prompt_choose_cards falls back to a random
# pick, so an enemy that somehow picked this up wouldn't crash, but the
# card is intended for the player.
func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not owner or not owner.hand_facade:
		return
	var chosen: Array[Card] = await owner.hand_facade.prompt_choose_cards(2, "Sink 2 cards")
	for card in chosen:
		owner.hand_facade.sink_card(card)
		owner.hand_facade.draw_cards(1)
