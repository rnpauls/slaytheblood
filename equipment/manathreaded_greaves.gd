class_name ManathreadedGreavesEquipment
extends Equipment

const BUFF_STATUS = preload("res://statuses/next_action_ap_buff.tres")


func on_block_consumed(owner_node: Node) -> void:
	if owner_node is Player and owner_node.status_handler:
		var buff := BUFF_STATUS.duplicate()
		buff.stacks = 1
		owner_node.status_handler.add_status(buff)
