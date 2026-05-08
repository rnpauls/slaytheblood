extends Card

const THORNS_STATUS = preload("res://statuses/thorns.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not owner or not owner.status_handler:
		return
	var thorns := THORNS_STATUS.duplicate()
	thorns.stacks = 3
	thorns.duration = 1
	owner.status_handler.add_status(thorns)
