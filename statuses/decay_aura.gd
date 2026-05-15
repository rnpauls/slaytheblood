## Decay Aura: Toxic Ghost passive. At the end of the player's turn (while the
## bearer is still alive), apply 1 Bleed to the player. Forces the player to
## either trade attrition with the Ghost or burn cards on healing — turning a
## stall fight into a slow squeeze.
##
## Auto-detaches when the bearer dies via _exit_tree, so the aura doesn't
## haunt the encounter after the source is gone.
class_name DecayAuraStatus
extends Status

const BLEED_TICK := 1
const BLEED_STATUS := preload("res://statuses/bleed.tres")

var _bearer: Enemy = null
var _bound_tick: Callable


func get_tooltip() -> String:
	return tooltip


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	_bound_tick = _on_player_turn_ended
	if not Events.player_turn_ended.is_connected(_bound_tick):
		Events.player_turn_ended.connect(_bound_tick)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_player_turn_ended() -> void:
	if not is_instance_valid(_bearer) or _bearer.stats == null or _bearer.stats.health <= 0:
		return
	var player := _find_player()
	if player == null or player.status_handler == null:
		return
	var dup: BleedStatus = BLEED_STATUS.duplicate()
	dup.duration = BLEED_TICK
	player.status_handler.add_status(dup)


func _find_player() -> Node:
	if not is_instance_valid(_bearer) or not _bearer.is_inside_tree():
		return null
	return _bearer.get_tree().get_first_node_in_group("player")


func _exit_tree() -> void:
	if _bound_tick and Events.player_turn_ended.is_connected(_bound_tick):
		Events.player_turn_ended.disconnect(_bound_tick)
