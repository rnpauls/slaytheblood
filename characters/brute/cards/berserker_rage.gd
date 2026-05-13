## Burn HP for permanent +Strength (Muscle) this battle. No duration set
## means the stacks stick around for the rest of the fight.
extends Card

@export var hp_cost: int = 4
@export var muscle_stacks: int = 2


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.stats == null:
		return
	owner.stats.health -= hp_cost
	if owner.status_handler:
		var muscle: MuscleStatus = preload("res://statuses/muscle.tres").duplicate()
		muscle.stacks = muscle_stacks
		owner.status_handler.add_status(muscle)
