extends Relic


func activate_relic(relic_ui: RelicUI) -> void:
	var player := self.owner as Player
	if not player or not player.status_handler:
		return
	var runechant: Status = player.status_handler.get_status_by_id("runechant")
	if runechant and runechant.stacks > 0:
		relic_ui.flash()
		player.stats.block += 1
