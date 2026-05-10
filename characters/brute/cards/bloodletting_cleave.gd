## Berserker tempo: pay HP for outsized damage. 8-attack for 1 mana is
## above the curve; the 3 HP cost is the brake.
extends Card

@export var hp_cost: int = 3


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if owner and owner.stats:
		owner.stats.health -= hp_cost
	do_stock_attack_damage_effect(targets, modifiers)
