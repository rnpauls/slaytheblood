extends Weapon

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	var player = targets[0].get_tree().get_first_node_in_group("player") as Player
	var is_flowing: bool = player.status_handler._has_status("flow")
	if is_flowing:
		go_again = true
	else:
		go_again = false
	super.activate_weapon(targets, modifiers)
	
