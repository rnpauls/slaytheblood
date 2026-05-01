extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func play(card_parent: Node, targets: Array[Node], char_stats: Stats, modifiers: ModifierHandler) -> void:
	await super.play(card_parent, targets, char_stats, modifiers)
	go_again = false

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit = OnHit.new()
	on_hit.custom_func = _on_hit_go_again
	on_hit.args = [self] as Array[Card]
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_go_again(_target: Node, args: Array[Card]):
	args[0].go_again = true
