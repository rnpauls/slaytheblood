extends Card

const MARKED_STATUS = preload("res://statuses/marked.tres")


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		return
	var marked := MARKED_STATUS.duplicate()
	marked.stacks = 2
	marked.duration = 1
	targets[0].status_handler.add_status(marked)
