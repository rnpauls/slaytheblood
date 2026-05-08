class_name ScabskinLeathersEquipment
extends Equipment


func use_active_ability(owner_node: Node) -> void:
	var player := owner_node as Player
	if not player or not player.stats or player.stats.action_points < 1:
		return
	player.stats.action_points -= 1
	var roll := RNG.instance.randi_range(1, 6)
	var gained := roll / 2
	player.stats.action_points += gained
	print("Scabskin Leathers rolled %d, gained %d AP" % [roll, gained])
	super.use_active_ability(owner_node)
