extends Relic

var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.player_first_attack_played.connect(_on_first_attack)


func _on_first_attack(_card: Card) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.stats:
		player.stats.action_points += 1


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.player_first_attack_played.is_connected(_on_first_attack):
		Events.player_first_attack_played.disconnect(_on_first_attack)
