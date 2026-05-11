class_name SpellbindersRobeEquipment
extends Equipment


func use_active_ability(owner_node: Node) -> void:
	var player := owner_node as Player
	if not player or not player.stats:
		return
	if player.stats.action_points < 1:
		return
	player.stats.action_points -= 1
	var amount := 0
	if player.status_handler:
		var rune := player.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			amount = rune.stacks
	player.stats.mana += amount
	player.stats.action_points += 1
	super.use_active_ability(owner_node)
	Events.equipment_self_destruct_requested.emit(self)
