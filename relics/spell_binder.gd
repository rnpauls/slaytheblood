extends Relic

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")


func activate_relic(relic_ui: RelicUI) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.status_handler:
		var rune := RUNECHANT_STATUS.duplicate()
		rune.stacks = 2
		player.status_handler.add_status(rune)
