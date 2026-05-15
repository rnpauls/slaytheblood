## Reassemble: Bone Knight passive. The first time the bearer drops to or below
## half HP without dying, restore +HEAL HP and shuffle every card in their
## exhaust pile back into their draw pile. One-shot per battle, so the
## comeback is dramatic but not perpetual.
##
## Triggers off Events.combatant_damaged (post-block, post-resolve), filtered
## to the bearer. The killing-blow case is intentionally skipped — Reassemble
## is a "you thought you had me" moment, not a literal resurrection.
class_name ReassembleStatus
extends Status

const HEAL_AMOUNT := 15

var _bearer: Enemy = null
var _bound_check: Callable
var _has_fired: bool = false


func get_tooltip() -> String:
	if _has_fired:
		return tooltip + " (already triggered)"
	return tooltip


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	_bound_check = _on_combatant_damaged
	if not Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.connect(_bound_check)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_combatant_damaged(victim: Node, _attacker: Node, _damage: int) -> void:
	if _has_fired or victim != _bearer:
		return
	if not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	if _bearer.stats.health <= 0:
		return  # killed by this hit; the comeback can't fire from a corpse
	var half_hp := float(_bearer.stats.max_health) / 2.0
	if float(_bearer.stats.health) > half_hp:
		return
	_has_fired = true
	_reassemble()


func _reassemble() -> void:
	if not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	# Heal first so the visible HP bump precedes the deck-pile churn.
	var new_hp: int = mini(_bearer.stats.max_health, _bearer.stats.health + HEAL_AMOUNT)
	_bearer.stats.health = new_hp
	if _bearer.stats.exhaust == null or _bearer.stats.draw_pile == null:
		return
	# Move every exhausted card back into the draw pile, then reshuffle.
	# Iterate over a copy so erasing from cards as we go is safe.
	var to_restore: Array = _bearer.stats.exhaust.cards.duplicate()
	for card: Card in to_restore:
		_bearer.stats.exhaust.cards.erase(card)
		_bearer.stats.draw_pile.add_card(card)
	_bearer.stats.exhaust.card_pile_size_changed.emit(_bearer.stats.exhaust.cards.size())
	_bearer.stats.draw_pile.shuffle()
	status_changed.emit()  # refresh tooltip to show "already triggered"


func _exit_tree() -> void:
	if _bound_check and Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.disconnect(_bound_check)
