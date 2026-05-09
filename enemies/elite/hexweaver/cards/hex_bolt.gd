extends Card

# Hex Bolt: small physical hit + chunky arcane zap. Pierces block, threatens
# the player's mana pool.

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
