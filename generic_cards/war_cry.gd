## War Cry: NAA. All allied enemies (including the caller) gain Empower 2 —
## their next attack each lands +2 damage. Marauder signature but generic so
## any leader-style enemy can pick it up.
extends Card

const EMPOWERED_STATUS := preload("res://statuses/empowered.tres")
const STACKS := 2


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if not (n is Combatant and n.stats and n.stats.health > 0 and n.status_handler):
			continue
		var dup: EmpoweredStatus = EMPOWERED_STATUS.duplicate()
		dup.stacks = STACKS
		dup.duration = 1
		n.status_handler.add_status(dup)
