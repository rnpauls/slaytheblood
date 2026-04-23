extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var top_card_arr : Array[Card]
	var top_pitch = 0
	#if target[0] is Player:
		#topPitch = targets[0].stats.draw_pile[0].pitch
	#elif target[0] is Enemy:
	top_card_arr = modifiers.get_parent().stats.draw_pile.reveal_top_cards(1)
	if top_card_arr.is_empty():
		top_pitch = 0
		print_debug("rabble on empty deck")
	else:
		top_pitch = top_card_arr[0].pitch
		print_debug("Revealed %s to rabble" % 	top_card_arr[0].id)
	
	do_stock_attack_damage_effect(targets, modifiers, attack-top_pitch)
