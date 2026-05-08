class_name HeavyGreavesEquipment
extends Equipment

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")


func on_destroyed(owner_node: Node) -> void:
	if owner_node is Player and owner_node.status_handler:
		var empower := EMPOWER_STATUS.duplicate()
		empower.duration = 1
		empower.stacks = 2
		owner_node.status_handler.add_status(empower)
