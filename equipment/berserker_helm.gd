class_name BerserkerHelmEquipment
extends Equipment


func on_block_consumed(owner_node: Node) -> void:
	if owner_node is Player and owner_node.status_handler:
		MuscleStatus.apply_temporary(owner_node.status_handler, 1)
