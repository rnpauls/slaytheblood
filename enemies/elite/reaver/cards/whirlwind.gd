extends Card

# Whirlwind: ALL_ENEMIES target — for the Reaver fighting solo this is
# functionally a single hit on the player, but the broad targeting means a
# captured copy is genuinely AOE for the player.

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
