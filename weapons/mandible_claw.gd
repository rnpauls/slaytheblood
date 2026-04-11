extends Weapon

func activate_weapon(targets: Array[Node]) -> void:
	var dmg_effect = DamageEffect.new()
	dmg_effect.amount = attack
	dmg_effect.execute(targets)
	var player = targets[0].get_tree().get_first_node_in_group("player") as Player
	player.stats.mana -= cost
	var is_enraged: bool = player.status_handler._has_status("enraged")
	if not is_enraged:
		player.stats.action_points -= 1
	attacks_this_turn += 1
	if attacks_this_turn >= attacks_per_turn: weapon_used_up.emit()
	
