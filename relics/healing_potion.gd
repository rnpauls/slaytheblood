extends Relic

@export var heal_amount := 6

func activate_relic(relic_ui: RelicUI) -> void:
	var player := self.owner as Player
	if player:
		player.stats.heal(heal_amount)
		relic_ui.flash()
