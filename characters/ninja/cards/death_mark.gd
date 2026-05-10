## Single-target heavy Marked applier. Mirrors mark_for_death but bigger
## (6 stacks vs 4) at higher cost — the Marked Assassin's nuke setup.
extends Card

const MARKED_STATUS = preload("res://statuses/marked.tres")

@export var stacks_amount: int = 6


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		return
	var marked := MARKED_STATUS.duplicate()
	marked.stacks = stacks_amount
	marked.duration = 1
	targets[0].status_handler.add_status(marked)
