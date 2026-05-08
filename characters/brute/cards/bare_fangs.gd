extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if owner is Player:
		Events.lock_hand.emit()
	var custom_attack: int
	if await sixloot(owner, 1):
		custom_attack = attack + 2
	else:
		custom_attack = attack
	do_stock_attack_damage_effect(targets, modifiers, custom_attack)
	if owner is Player:
		Events.unlock_hand.emit()
