## Block-as-damage. The swing's damage equals the brute's current block
## value, scaling with how much defense they've stockpiled. Pairs with
## Iron Hide / Bulwark; doesn't consume the block.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if owner == null:
		return
	var damage := owner.stats.block
	if damage <= 0:
		return
	do_stock_attack_damage_effect(targets, modifiers, damage)
