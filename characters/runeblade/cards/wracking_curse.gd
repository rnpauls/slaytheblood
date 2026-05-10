## Pure debuff stacker: pile Marked AND Brittle on a single target so any
## attack landed against them this turn hits about 2× harder. No damage of
## its own — pairs with a follow-up swing or runic detonation.
extends Card

const MARKED_STATUS := preload("res://statuses/marked.tres")
const EXPOSED_STATUS := preload("res://statuses/exposed.tres")

@export var marked_stacks: int = 3
@export var brittle_duration: int = 2


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		return
	var target_node := targets[0]
	if target_node.status_handler == null:
		return
	var marked := MARKED_STATUS.duplicate()
	marked.stacks = marked_stacks
	marked.duration = 1
	target_node.status_handler.add_status(marked)
	var brittle := EXPOSED_STATUS.duplicate()
	brittle.duration = brittle_duration
	target_node.status_handler.add_status(brittle)
