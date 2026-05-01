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
	target.attack_completed.connect(apply_status.bind(target))
	if target is Player:
		Events.player_turn_ended.connect(apply_status.bind(target))
	else:
		Events.enemy_phase_ended.connect(apply_status.bind(target))
		
	print_debug("Add empowered modifier")

func update() -> void:
	damage_modifier.set_value_flat_value("empowered", stacks)

func apply_status(_target) -> void:
	status_applied.emit(self)

func _exit_tree() -> void:
	damage_modifier.remove_value("empowered")
