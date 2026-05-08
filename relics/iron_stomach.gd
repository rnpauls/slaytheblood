extends Relic


func activate_relic(owner: RelicUI) -> void:
	var player_handler: PlayerHandler = owner.get_tree().get_first_node_in_group("player_handler")
	if not player_handler or not player_handler.hand:
		return
	var has_big: bool = false
	for child in player_handler.hand.get_children():
		if child is PlayerCardUI and child.card and child.card.attack >= 6:
			has_big = true
			break
	if has_big:
		owner.flash()
		var player := owner.get_tree().get_first_node_in_group("player") as Player
		if player:
			player.stats.mana += 1
