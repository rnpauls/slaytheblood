## Burn HP for a fat Empower load. Empower's duration=1 means the buff
## expires at turn end (or after one attack) — so this is a setup for an
## immediate big swing, not a long-term engine.
extends Card

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")

@export var hp_cost: int = 4
@export var empower_stacks: int = 4


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.stats == null:
		return
	owner.stats.health -= hp_cost
	if owner.status_handler:
		var empower := EMPOWER_STATUS.duplicate()
		empower.stacks = empower_stacks
		empower.duration = 1
		owner.status_handler.add_status(empower)
