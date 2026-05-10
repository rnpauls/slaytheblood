## Spend all remaining mana to power up an arcane bolt. Deals base zap plus
## one extra arcane per drained mana. The play pattern: pitch a fat hand for
## mana, then dump it into one big spell — the inverse of usual mana-spend
## loops where mana is purely defensive against arcane.
extends Card

@export var base_zap: int = 3


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var bonus := 0
	if owner and owner.stats:
		bonus = owner.stats.mana
		owner.stats.mana = 0
	do_zap_effect(targets, modifiers, base_zap + bonus)
