extends Card


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if await sixloot(owner, 2):
		go_again = true
		MuscleStatus.apply_temporary(owner.status_handler, 2)
