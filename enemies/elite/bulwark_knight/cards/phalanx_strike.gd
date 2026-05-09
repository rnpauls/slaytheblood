extends Card

# Attack value scales with the wielder's current block — punishes a turtling
# Bulwark Knight that's been stockpiling.

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var total := attack
	if owner:
		total += owner.stats.block
	do_stock_attack_damage_effect(targets, modifiers, total)


func get_attack_value() -> int:
	if owner:
		return attack + owner.stats.block
	return attack
