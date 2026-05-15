class_name TabiBootsEquipment
extends Equipment


func initialize_equipment(owner_node) -> void:
	super.initialize_equipment(owner_node)
	if not Events.player_first_card_played.is_connected(_on_first_card_played):
		Events.player_first_card_played.connect(_on_first_card_played)


func _on_first_card_played(_card: Card) -> void:
	if owner is Player and owner.stats:
		owner.stats.action_points += 1
		if handler:
			handler.flash()


func deactivate_equipment(_owner_node: Node) -> void:
	if Events.player_first_card_played.is_connected(_on_first_card_played):
		Events.player_first_card_played.disconnect(_on_first_card_played)
