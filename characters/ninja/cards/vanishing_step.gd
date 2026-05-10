## Tighter Flicker Step: sink 1, draw 2 (instead of sink 2, draw 1).
## Player-only by design — see flicker_step.gd notes.
extends Card


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not owner or not owner.hand_facade:
		return
	var chosen: Array[Card] = await owner.hand_facade.prompt_choose_cards(1, "Sink a card")
	for card in chosen:
		owner.hand_facade.sink_card(card)
	owner.hand_facade.draw_cards(2)
