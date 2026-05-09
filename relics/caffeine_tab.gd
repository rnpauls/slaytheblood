extends Relic

var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.player_first_card_played.connect(_on_first_card)


func _on_first_card(_card: Card) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.stats:
		player.stats.mana += 1


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.player_first_card_played.is_connected(_on_first_card):
		Events.player_first_card_played.disconnect(_on_first_card)
