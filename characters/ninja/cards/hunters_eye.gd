## AoE Marked applier. Apply Marked N to every living enemy — opens up the
## Marked Assassin payoff cards (Bullseye, Executioner) against the whole room.
extends Card

const MARKED_STATUS = preload("res://statuses/marked.tres")

@export var stacks_amount: int = 3


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	for target in targets:
		if target == null or target.status_handler == null:
			continue
		var marked := MARKED_STATUS.duplicate()
		marked.stacks = stacks_amount
		marked.duration = 1
		target.status_handler.add_status(marked)
