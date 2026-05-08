extends Card

const MUSCLE_STATUS = preload("res://statuses/muscle.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not owner:
		return
	var enemies :Array[Combatant] = owner.get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == owner or not is_instance_valid(e):
			continue
		if e.stats.health <= 0:
			continue
		var muscle := MUSCLE_STATUS.duplicate()
		muscle.stacks = 1
		e.status_handler.add_status(muscle)
