extends Relic


func activate_relic(relic_ui: RelicUI) -> void:
	var player := self.owner as Player
	if not player or not player.player_handler or not player.player_handler.hand:
		return
	var has_big: bool = false
	for child in player.player_handler.hand.get_children():
		if child is PlayerCardUI and child.card and child.card.attack >= 6:
			has_big = true
			break
	if has_big:
		relic_ui.flash()
		player.stats.mana += 1
