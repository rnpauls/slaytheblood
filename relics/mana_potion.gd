extends Relic


func activate_relic(relic_ui: RelicUI) -> void:
	Events.player_action_phase_started.connect(_add_mana.bind(relic_ui), CONNECT_ONE_SHOT)


func _add_mana(relic_ui: RelicUI) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player:
		player.stats.mana += 1
