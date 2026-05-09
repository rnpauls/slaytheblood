extends Card

# Frenzy: small base attack + 3 per Muscle stack on the wielder. Combos with
# Bloodlust to ramp into terrifying late-fight burst.

func _bonus_from_muscle() -> int:
	if owner and owner.status_handler:
		var m := owner.status_handler.get_status_by_id("muscle")
		if m:
			return m.stacks * 3
	return 0


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers, attack + _bonus_from_muscle())


func get_attack_value() -> int:
	return attack + _bonus_from_muscle()
