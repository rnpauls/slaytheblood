extends Relic

var relic_ui: RelicUI


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.player_first_card_played.connect(_on_first_card)


func _on_first_card(_card: Card) -> void:
	relic_ui.flash()
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if player and player.stats:
		player.stats.mana += 1


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_first_card_played.is_connected(_on_first_card):
		Events.player_first_card_played.disconnect(_on_first_card)
