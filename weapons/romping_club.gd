extends Weapon

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	var player = targets[0].get_tree().get_first_node_in_group("player") as Player
	var is_enraged: bool = player.status_handler._has_status("enraged")
	var temp_attack: int
	if is_enraged:
		temp_attack = attack +1
	else:
		temp_attack = attack
	super.activate_weapon(targets, modifiers, temp_attack)
	
