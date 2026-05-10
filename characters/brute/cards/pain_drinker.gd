## Pay HP for permanent-this-turn damage. Uses MuscleStatus.apply_temporary
## so the +damage decays at end of turn — without that, this would be a
## permanent-Strength engine for ~free.
extends Card

@export var hp_cost: int = 2
@export var muscle_stacks: int = 2


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.stats == null:
		return
	owner.stats.health -= hp_cost
	if owner.status_handler:
		MuscleStatus.apply_temporary(owner.status_handler, muscle_stacks)
