class_name SmokeCapsuleEquipment
extends Equipment


func on_block_consumed(owner_node: Node) -> void:
	if owner_node is Combatant and owner_node.hand_facade:
		owner_node.hand_facade.draw_cards(1)
