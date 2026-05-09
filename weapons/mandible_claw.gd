extends Weapon

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	var is_enraged: bool = owner != null and owner.status_handler.has_status("enraged")
	if is_enraged:
		go_again = true
	else:
		go_again = false
	super.activate_weapon(targets, modifiers)
	
