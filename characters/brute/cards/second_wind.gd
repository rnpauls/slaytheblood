extends Card


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner is Player:
		Events.lock_hand.emit()
	if await sixloot(owner, 0):
		owner.stats.action_points += 2
	if owner is Player:
		Events.unlock_hand.emit()
