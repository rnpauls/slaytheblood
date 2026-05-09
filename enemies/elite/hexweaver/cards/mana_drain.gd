extends Card

# Mana Drain: zeros the target's mana. Brutal against arcane-defense builds.

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	for target in targets:
		if target and target.get("stats"):
			target.stats.mana = 0
