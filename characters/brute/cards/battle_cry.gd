extends Card

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner is Player:
		Events.lock_hand.emit()
	if await sixloot(owner, 1):
		var empower := EMPOWER_STATUS.duplicate()
		empower.stacks = 4
		empower.duration = 1
		owner.status_handler.add_status(empower)
	if owner is Player:
		Events.unlock_hand.emit()
