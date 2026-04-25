extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var poison_tip_status = preload("res://statuses/poison_tip.tres").duplicate()
	poison_tip_status.stacks = 3
	targets[0].status_handler.add_status(poison_tip_status)
