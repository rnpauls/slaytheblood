## Ally Up: NAA. Picks one OTHER living ally and dumps Muscle 2 + 5 block on
## them. Cost 0 because the value is encounter-shape-dependent — useless solo
## (no other ally to buff), excellent in 2-3 enemy fights. AI ignores it
## naturally when alone via the no-target return.
extends Card

const MUSCLE_STATUS := preload("res://statuses/muscle.tres")
const MUSCLE_GAIN := 2
const BLOCK_GAIN := 5


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	var allies: Array = []
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if n == owner:
			continue
		if n is Combatant and n.stats and n.stats.health > 0 and n.status_handler:
			allies.append(n)
	if allies.is_empty():
		return
	var ally: Combatant = allies[randi() % allies.size()]
	var dup: MuscleStatus = MUSCLE_STATUS.duplicate()
	dup.stacks = MUSCLE_GAIN
	ally.status_handler.add_status(dup)
	ally.stats.block += BLOCK_GAIN
