extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit:= OnHit.new()
	var discard_eff:= DiscardRandomEffect.new()
	discard_eff.amount = 1
	on_hit.effect=discard_eff
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

	
