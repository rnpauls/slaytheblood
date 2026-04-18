extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var main_effect = OnHitDamageEffect.new()
	main_effect.amount = modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	main_effect.sound = sound
	main_effect.go_again = go_again
	var on_hit:= DiscardRandomEffect.new()
	on_hit.amount = 1
	main_effect.on_hit=on_hit
	
	main_effect.execute(targets)
