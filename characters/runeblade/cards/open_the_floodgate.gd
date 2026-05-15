## Zap 5 and seed 3 Floodgate for the NEXT arcane card. The granted Floodgate
## survives this card's own player_card_played because FloodgateStatus defers
## its decay-signal hookup, so it primes the next zap instead of self-consuming.
extends Card

const FLOODGATE_STATUS = preload("res://statuses/floodgate.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_zap_effect(targets, modifiers, zap)
	if owner == null or owner.status_handler == null:
		return
	var fg := FLOODGATE_STATUS.duplicate()
	fg.stacks = 3
	owner.status_handler.add_status(fg)
