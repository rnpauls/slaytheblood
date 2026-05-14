extends Weapon

func would_go_again() -> bool:
	if owner == null:
		return go_again
	return owner.status_handler.has_status("flow_state")

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	var is_flowing: bool = owner != null and owner.status_handler.has_status("flow_state")
	if is_flowing:
		go_again = true
	else:
		go_again = false
	super.activate_weapon(targets, modifiers)
