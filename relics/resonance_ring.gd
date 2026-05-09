extends Relic

var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.card_exhausted.connect(_on_card_exhausted)


func _on_card_exhausted(_card: Card) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.player_handler:
		player.player_handler.draw_card()


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.card_exhausted.is_connected(_on_card_exhausted):
		Events.card_exhausted.disconnect(_on_card_exhausted)
