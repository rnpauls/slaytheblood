extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var success:= await sixloot(modifiers.getparent(),2)
	if success:
		var status_handler : StatusHandler = modifiers.get_parent().status_handler
		go_again = true
		var damage_modifier = modifiers.get_modifier(Modifier.Type.DMG_DEALT)
		var dmg_modifier_value: ModifierValue = damage_modifier.get_value("bloodrushed")
		if dmg_modifier_value:
			var new_dmg_modifier_value: ModifierValue = ModifierValue.create_new_modifier("bloodrushed", ModifierValue.Type.FLAT)
			new_dmg_modifier_value.flat_value = dmg_modifier_value.flat_value + 2
			damage_modifier.add_new_value(new_dmg_modifier_value)
		var bloodrush_status = preload("res://statuses/bloodrushed.tres").duplicate()
		status_handler.add_status(bloodrush_status)
