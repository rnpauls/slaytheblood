## "Death's Door" attack: damage scales with how much HP the brute has lost.
## Base + 1 per missing 5 HP — so at 26/66 HP that's 6 + 8 = 14 damage for
## a 0-cost card. Late-fight finisher; risky to chip with HP-pay cards
## (Bloodletting, Pain Drinker) early to load this up.
extends Card

@export var per_threshold: int = 5


func get_default_tooltip() -> String:
	return tooltip_text % [attack, per_threshold]


func get_updated_tooltip(player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	var bonus := _missing_hp_bonus()
	var total := attack + bonus
	if player_modifiers:
		total = player_modifiers.get_modified_value(total, Modifier.Type.DMG_DEALT)
	return "Deal %s damage (+1 per %s HP missing)." % [total, per_threshold]


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage := attack + _missing_hp_bonus()
	do_stock_attack_damage_effect(targets, modifiers, damage)


func _missing_hp_bonus() -> int:
	if owner == null or owner.stats == null:
		return 0
	var missing := owner.stats.max_health - owner.stats.health
	if missing <= 0:
		return 0
	return missing / per_threshold
