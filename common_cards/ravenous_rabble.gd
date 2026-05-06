extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var source_owner: Node = modifiers.get_parent()
	var top_card_arr: Array[Card] = source_owner.stats.draw_pile.reveal_top_cards(1)
	var top_pitch := 0
	if top_card_arr.is_empty():
		print_debug("rabble on empty deck")
	else:
		top_pitch = top_card_arr[0].pitch
		print_debug("Revealed %s to rabble" % top_card_arr[0].id)
		# Animate the reveal so the player sees what was on top before damage hits.
		# BattleUI routes by owner (player → draw pile, enemy → transient overlay).
		Events.top_card_reveal_requested.emit(top_card_arr[0], source_owner)
		await Events.top_card_reveal_finished

	do_stock_attack_damage_effect(targets, modifiers, attack - top_pitch)
