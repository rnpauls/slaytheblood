extends Card

# Reckless Charge: high damage, but Reaver takes 3 unmodifiable self-damage.

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
	if owner:
		owner.take_damage(3, Modifier.Type.NO_MODIFIER, Card.DamageKind.PHYSICAL, 0)
