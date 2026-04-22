class_name BloodrushedStatus
extends Status

var damage_modifier: Modifier

func initialize_status(target: Node) -> void:
	damage_modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	var dmg_modifier_value: ModifierValue = ModifierValue.create_new_modifier("bloodrushed", ModifierValue.Type.FLAT)
	dmg_modifier_value.flat_value = stacks
	print_debug("can bloodrush stack?")
	damage_modifier.add_new_value(dmg_modifier_value)



func _exit_tree() -> void:
	damage_modifier.remove_value("bloodrushed")
