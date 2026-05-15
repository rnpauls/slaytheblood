## BatBite: Pack Bat passive. When the bearer dies, drop one Trash card into
## the player's discard pile — punishes the player for trading hits with a
## flock by polluting the cycle they'll soon redraw.
##
## Hooks Events.enemy_died (filtered to the bearer) so the deposit fires after
## any attacker-side reactions but before the next enemy phase.
class_name BatBiteStatus
extends Status

const TRASH_CARD := preload("res://generic_cards/trash.tres")

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
	if player == null:
		return
	var effect := CardAddEffect.new()
	effect.card_to_add = TRASH_CARD
	effect.destination = CardAddEffect.Destination.DISCARD_PILE
	effect.execute([player])


func _find_player() -> Node:
	if not is_instance_valid(_bearer) or not _bearer.is_inside_tree():
		return null
	return _bearer.get_tree().get_first_node_in_group("player")


func _exit_tree() -> void:
	if _bound_on_died and Events.enemy_died.is_connected(_bound_on_died):
		Events.enemy_died.disconnect(_bound_on_died)
