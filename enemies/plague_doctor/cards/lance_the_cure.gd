## Lance the Cure: Plague Doctor support card. Heals every living allied
## enemy for HEAL_AMOUNT. The Doctor herself is included via the "enemies"
## group iteration. Useless solo (no ally to heal); shines when paired with
## Plague Rats — keeps the rat swarm alive longer for their Disease Carrier
## detonation on death.
extends Card

const HEAL_AMOUNT := 4


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if n is Combatant and n.stats and n.stats.health > 0:
			n.stats.heal(HEAL_AMOUNT)
