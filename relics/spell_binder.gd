extends Relic

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")


func activate_relic(owner: RelicUI) -> void:
	owner.flash()
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player and player.status_handler:
		var rune := RUNECHANT_STATUS.duplicate()
		rune.stacks = 2
		player.status_handler.add_status(rune)
