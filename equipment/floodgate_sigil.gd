## OFFHAND. When this equipment soaks an attack, the runic sigil floods the
## wielder with arcane potential — gain 1 Floodgate for the next arcane card.
class_name FloodgateSigilEquipment
extends Equipment

const FLOODGATE_STATUS = preload("res://statuses/floodgate.tres")


func on_block_consumed(owner_node: Node) -> void:
	if owner_node is Player and owner_node.status_handler:
		var fg := FLOODGATE_STATUS.duplicate()
		fg.stacks = 1
		owner_node.status_handler.add_status(fg)
