class_name EmpoweredStatus
extends Status

var damage_modifier: Modifier

#Adds "stacks" to next attack power
#Set duration to 2 if created by an attack (it will reduce duration by 1 when attack is completed)

func get_tooltip() -> String:
	return tooltip % stacks

func initialize_status(target: Node) -> void:
	damage_modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	var dmg_modifier_value: ModifierValue = ModifierValue.create_new_modifier("empowered", ModifierValue.Type.FLAT)
	dmg_modifier_value.flat_value = stacks
	damage_modifier.add_new_value(dmg_modifier_value)
	if target is Player:
		var player_handler: PlayerHandler = target.get_tree().get_first_node_in_group("player_handler")
		player_handler.attack_completed.connect(apply_status.bind(target))
		Events.player_turn_ended.connect(apply_status.bind(target))
	else:
		target.attack_completed.connect(apply_status.bind(target))
		Events.enemy_phase_ended.connect(apply_status.bind(target))
		
	print_debug("Add bittering thorns modifier")


func apply_status(_target) -> void:
	status_applied.emit(self)

func _exit_tree() -> void:
	damage_modifier.remove_value("empowered")
