class_name CncEffect
extends Effect

#var amount := 1


func execute(targets: Array[Node]) -> void:
	var card
	if targets.is_empty():
		return
	if targets[0] is Player:
		var player_handler := targets[0].get_tree().get_first_node_in_group("player_handler") as PlayerHandler
		if not player_handler:
			return
		card = player_handler.arsenal
		card.queue_free()
		for targetx in targets:
			print("Support targetting everyone")
	else:
		for targetx: Enemy in targets:
			card = targetx.enemy_ai.arsenal
			if card: card.queue_free()
			print_debug(targetx.enemy_ai.arsenal == null)
