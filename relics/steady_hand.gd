extends Relic

var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	# Starter relics: owner is null until PlayerHandler.start_battle wires it,
	# which emits player_set_up. CONNECT_ONE_SHOT so it only fires once per run.
	if self.owner == null:
		Events.player_set_up.connect(_apply_once, CONNECT_ONE_SHOT)
	else:
		_apply_once()


func _apply_once() -> void:
	var player := self.owner as Player
	if player and player.stats:
		player.stats.cards_per_turn += 1
		if relic_ui:
			relic_ui.flash()


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.player_set_up.is_connected(_apply_once):
		Events.player_set_up.disconnect(_apply_once)
