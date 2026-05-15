## Zap 4 and seed 1 Floodgate for the next arcane card.
extends Card

const FLOODGATE_STATUS = preload("res://statuses/floodgate.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_zap_effect(targets, modifiers, zap)
	if owner == null or owner.status_handler == null:
		return
	var fg := FLOODGATE_STATUS.duplicate()
	fg.stacks = 1
	owner.status_handler.add_status(fg)
