extends Card

# Drain Touch: standard hit + heals the wielder for 3.

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
	if owner:
		owner.stats.heal(3)
