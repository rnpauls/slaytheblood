## Big draw turn for the Brute: draw 3, gain Empower 2 for the rest of the turn.
## Mirrors battle_cry's Empower setup (duration 1 so it expires at turn-end).
extends Card

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")

@export var draw_amount: int = 3
@export var empower_amount: int = 2


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if draw_amount > 0:
		var card_draw := CardDrawEffect.new()
		card_draw.cards_to_draw = draw_amount
		card_draw.execute([owner])

	if empower_amount > 0 and owner and owner.status_handler:
		var empower := EMPOWER_STATUS.duplicate()
		empower.stacks = empower_amount
		empower.duration = 1
		owner.status_handler.add_status(empower)
