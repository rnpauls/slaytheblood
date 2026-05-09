extends Card

# Counter Slam: +6 attack if the wielder has any block when this resolves.
# Encourages the player to either fully break the Bulwark's block first, or
# accept the boosted hit.

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var total := attack
	if owner and owner.stats.block > 0:
		total += 6
	do_stock_attack_damage_effect(targets, modifiers, total)


func get_attack_value() -> int:
	if owner and owner.stats.block > 0:
		return attack + 6
	return attack
