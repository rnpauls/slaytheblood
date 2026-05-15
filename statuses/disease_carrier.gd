## DiseaseCarrier: Plague Rat passive. When the bearer dies, apply Bleed 3 to
## the player. Doesn't matter who landed the killing blow — the player carries
## the rat's last gift either way (only one player target). Hooks
## Events.enemy_died filtered to the bearer.
class_name DiseaseCarrierStatus
extends Status

const BLEED_STATUS := preload("res://statuses/bleed.tres")
const BLEED_DURATION := 3

var _bearer: Enemy = null
var _bound_on_died: Callable
var _has_fired: bool = false


func get_tooltip() -> String:
	return tooltip


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	_bound_on_died = _on_enemy_died
	if not Events.enemy_died.is_connected(_bound_on_died):
		Events.enemy_died.connect(_bound_on_died)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_enemy_died(dead: Enemy) -> void:
	if _has_fired or dead != _bearer:
		return
	_has_fired = true
	var player := _find_player()
	if player == null or player.status_handler == null:
		return
	var dup: BleedStatus = BLEED_STATUS.duplicate()
	dup.duration = BLEED_DURATION
	player.status_handler.add_status(dup)


func _find_player() -> Node:
	if not is_instance_valid(_bearer) or not _bearer.is_inside_tree():
		return null
	return _bearer.get_tree().get_first_node_in_group("player")


func _exit_tree() -> void:
	if _bound_on_died and Events.enemy_died.is_connected(_bound_on_died):
		Events.enemy_died.disconnect(_bound_on_died)
