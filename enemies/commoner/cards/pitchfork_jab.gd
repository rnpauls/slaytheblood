## Pitchfork Jab: Commoner attack that gets +2 atk if any other Commoner is
## still alive in the encounter. Encourages keeping multiple Commoners around
## as a swarm — kill them one at a time and the survivors hit weaker.
##
## get_attack_value override means the displayed intent damage tracks the
## buff in real time (Enemy.update_intent calls get_attack_value).
extends Card

const ALLY_NAME := "Commoner"
const ALLY_BONUS := 2


func get_attack_value() -> int:
	if owner == null or not owner.is_inside_tree():
		return attack
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if n == owner:
			continue
		if n is Enemy and n.stats and n.stats.character_name == ALLY_NAME and n.stats.health > 0:
			return attack + ALLY_BONUS
	return attack


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers, get_attack_value())
