extends Relic

var relic_ui: RelicUI


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.card_exhausted.connect(_on_card_exhausted)


func _on_card_exhausted(_card: Card) -> void:
	relic_ui.flash()
	var player_handler: PlayerHandler = relic_ui.get_tree().get_first_node_in_group("player_handler")
	if player_handler:
		player_handler.draw_card()


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.card_exhausted.is_connected(_on_card_exhausted):
		Events.card_exhausted.disconnect(_on_card_exhausted)
