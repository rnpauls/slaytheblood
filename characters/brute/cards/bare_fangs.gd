extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	Events.lock_hand.emit()
	var player_handler: PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	var custom_attack: int
	if sixloot(player_handler, 1):
		custom_attack = attack + 2
	else:
		custom_attack = attack
	do_stock_attack_damage_effect(targets, modifiers, custom_attack)
	Events.unlock_hand.emit()
