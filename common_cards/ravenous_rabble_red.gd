extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var topPitch : int
	#if target[0] is Player:
		#topPitch = targets[0].stats.draw_pile[0].pitch
	#elif target[0] is Enemy:
	topPitch = modifiers.get_parent().stats.draw_pile[0].pitch
	print_debug("Revealed %s to rabble" % 	modifiers.get_parent().stats.draw_pile[0])
	
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(attack-topPitch, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)
