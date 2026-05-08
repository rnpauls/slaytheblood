extends Relic

const MUSCLE_STATUS = preload("res://statuses/muscle.tres")


func activate_relic(owner: RelicUI) -> void:
	owner.flash()
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player and player.status_handler:
		var muscle := MUSCLE_STATUS.duplicate()
		muscle.stacks = 1
		player.status_handler.add_status(muscle)
