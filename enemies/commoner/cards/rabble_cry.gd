## Rabble Cry: Commoner shouts; every allied enemy (incl. self) gains Muscle 1.
## NAA, no attack — pure encounter-aware buff. Iterates the "enemies" group so
## any enemy mix benefits, not just other Commoners.
extends Card

const MUSCLE_STATUS := preload("res://statuses/muscle.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if n is Combatant and n.stats and n.stats.health > 0 and n.status_handler:
			var dup: MuscleStatus = MUSCLE_STATUS.duplicate()
			dup.stacks = 1
			n.status_handler.add_status(dup)
