extends Weapon

func activate_weapon(targets: Array[Node], _custom_atk: int = attack) -> void:
	var player = targets[0].get_tree().get_first_node_in_group("player") as Player
	go_again = player.status_handler._has_status("flow")
	super.activate_weapon(targets)
	
