class_name HexAuraStatus
extends Status

# Granted by Cursed Staff. Each START_OF_TURN, applies one stack of Exposed
# (1-turn duration) to every opposing combatant.

const EXPOSED_STATUS := preload("res://statuses/exposed.tres")


func get_tooltip() -> String:
	return tooltip


func apply_status(target: Node) -> void:
	if target and target.is_inside_tree():
		var tree := target.get_tree()
		var opponents: Array
		if target is Enemy:
			opponents = tree.get_nodes_in_group("player")
		else:
			opponents = tree.get_nodes_in_group("enemies")

		for opponent in opponents:
			var sh :StatusHandler = opponent.get("status_handler")
			if sh is StatusHandler:
				var hex_exposed: Status = EXPOSED_STATUS.duplicate()
				hex_exposed.duration = 1
				sh.add_status(hex_exposed)
	status_applied.emit(self)
