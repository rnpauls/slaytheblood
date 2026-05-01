extends Weapon

func activate_weapon(targets: Array[Node], _custom_atk: int = attack) -> void:
	var player = targets[0].get_tree().get_first_node_in_group("player") as Player
	var is_enraged: bool = player.status_handler._has_status("enraged")
	super.activate_weapon(targets, attack + 1 if is_enraged else attack)
	
