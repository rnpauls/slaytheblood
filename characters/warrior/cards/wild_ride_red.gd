extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var milled_card: Card = targets[0].get_tree().get_first_node_in_group("player").stats.mill(1)[0]
	if milled_card:
		if milled_card.attack >= 6:
			go_again = true
		else:
			go_again = false
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)
