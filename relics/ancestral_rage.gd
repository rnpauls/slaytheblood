extends Relic

const MUSCLE_STATUS = preload("res://statuses/muscle.tres")


func activate_relic(relic_ui: RelicUI) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.status_handler:
		var muscle := MUSCLE_STATUS.duplicate()
		muscle.stacks = 1
		player.status_handler.add_status(muscle)
