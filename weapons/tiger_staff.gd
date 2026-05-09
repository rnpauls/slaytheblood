extends Weapon

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	
	super.activate_weapon(targets, modifiers)

	if owner == null:
		return
	var empowered_status = preload("res://statuses/empowered.tres").duplicate()
	empowered_status.duration = 1
	empowered_status.stacks = 1
	owner.status_handler.add_status(empowered_status)
	
