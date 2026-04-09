extends Weapon

func activate_weapon(targets: Array) -> void:
	var dmg_effect = DamageEffect.new()
	dmg_effect.amount = attack
	dmg_effect.execute(targets)
	var player = targets[0].get_tree().get_first_node_in_group("player")
	player.stats.mana -= cost
	if not six_discarded_this_turn:
		player.stats.action_points -= 1
	attacks_this_turn += 1
	
