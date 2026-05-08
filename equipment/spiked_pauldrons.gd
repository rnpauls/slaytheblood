class_name SpikedPauldronsEquipment
extends Equipment

const THORNS_STATUS = preload("res://statuses/thorns.tres")


func on_block_consumed(owner_node: Node) -> void:
	if owner_node is Player and owner_node.status_handler:
		var thorns := THORNS_STATUS.duplicate()
		thorns.stacks = 2
		thorns.duration = 1
		owner_node.status_handler.add_status(thorns)
