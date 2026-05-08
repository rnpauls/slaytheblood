extends Relic


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.status_handler:
		return
	var runechant: Status = player.status_handler.get_status_by_id("runechant")
	if runechant and runechant.stacks > 0:
		owner.flash()
		player.stats.block += 1
