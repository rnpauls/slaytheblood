## ARMS, single-use. Shatters on impact, but the mana flood it releases is huge:
## gain 4 Floodgate for the next arcane card. Mirrors heavy_greaves' on-destroy
## pattern.
class_name ManaglassVambracesEquipment
extends Equipment

const FLOODGATE_STATUS = preload("res://statuses/floodgate.tres")


func on_destroyed(owner_node: Node) -> void:
	if owner_node is Player and owner_node.status_handler:
		var fg := FLOODGATE_STATUS.duplicate()
		fg.stacks = 4
		owner_node.status_handler.add_status(fg)
