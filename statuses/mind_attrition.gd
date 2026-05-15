## MindAttrition: Mind Reaver opener. At battle start, pulls 2 random cards
## out of the player's draw pile and exhausts them — the player will see
## fewer of their own tools cycle this fight, hard.
##
## Fires once on initialize. The status itself sticks around as a passive
## badge (no further effect) so the player can hover and see what hit them.
class_name MindAttritionStatus
extends Status

const STEAL_COUNT := 2

var _bearer: Enemy = null
var _has_fired: bool = false


func get_tooltip() -> String:
	if _has_fired:
		return tooltip + " (already fired)"
	return tooltip


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	# Defer one frame so the player's deck is fully built (EnemyHandler runs
	# its setup pass first; the player handler races; deferring is safest).
	call_deferred("_fire")


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _fire() -> void:
	if _has_fired:
		return
	_has_fired = true
	var player := _find_player()
	if player == null or player.stats == null:
		status_changed.emit()
		return
	var draw: CardPile = player.stats.draw_pile
	var exhaust: CardPile = player.stats.exhaust
	if draw == null or exhaust == null:
		status_changed.emit()
		return
	for i in STEAL_COUNT:
		if draw.cards.is_empty():
			break
		var idx := randi() % draw.cards.size()
		var card: Card = draw.cards[idx]
		draw.cards.remove_at(idx)
		draw.card_pile_size_changed.emit(draw.cards.size())
		exhaust.add_card(card)
		Events.card_exhausted.emit(card)
	status_changed.emit()


func _find_player() -> Node:
	if not is_instance_valid(_bearer) or not _bearer.is_inside_tree():
		return null
	return _bearer.get_tree().get_first_node_in_group("player")
