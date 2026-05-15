## START_OF_TURN. Grant the player 1 Floodgate every turn so they always have
## a small zap multiplier ready for their first arcane card.
extends Relic

const FLOODGATE_STATUS = preload("res://statuses/floodgate.tres")


func activate_relic(relic_ui: RelicUI) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.status_handler:
		var fg := FLOODGATE_STATUS.duplicate()
		fg.stacks = 1
		player.status_handler.add_status(fg)
