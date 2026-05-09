## Pure draw card. Configurable via @export draw_amount on the .tres so the
## same script powers multiple cards (Arcane Insight = 2, Runic Scribe = 3,
## etc.). Targets SELF — the player draws into their own hand.
extends Card

@export var draw_amount: int = 2

func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if draw_amount <= 0:
		return
	var card_draw := CardDrawEffect.new()
	card_draw.cards_to_draw = draw_amount
	card_draw.execute([owner])
