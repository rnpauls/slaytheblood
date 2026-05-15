## Bloodied: passive that triggers once when the bearer drops to or below half
## HP. Grants Muscle 2 (permanent for the battle) AND bumps cards_per_turn by 1
## so the bearer also draws an extra card every subsequent enemy phase.
##
## One-shot per battle. The damage hook only checks "did this hit drop me at or
## below half?" — healing back above half doesn't re-arm the trigger. Killing
## blow is intentionally skipped: a phase shift on a corpse is silly.
class_name BloodiedStatus
extends Status

const MUSCLE_GAIN := 2
const EXTRA_DRAW := 1
const MUSCLE_STATUS := preload("res://statuses/muscle.tres")

var _bearer: Combatant = null
var _bound_check: Callable
var _has_fired: bool = false


func get_tooltip() -> String:
	if _has_fired:
		return tooltip + " (triggered)"
	return tooltip


func initialize_status(target: Node) -> void:
	if target == null:
		return
	_bearer = target as Combatant
	_bound_check = _on_combatant_damaged
	if not Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.connect(_bound_check)
	# Status might be applied to an already-low-HP bearer via debug or
	# mid-battle insert — check immediately so it doesn't sit dormant.
	_check()


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_combatant_damaged(victim: Node, _attacker: Node, _damage: int) -> void:
	if victim != _bearer:
		return
	_check()


func _check() -> void:
	if _has_fired:
		return
	if not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	if _bearer.stats.health <= 0:
		return
	var half := float(_bearer.stats.max_health) / 2.0
	if float(_bearer.stats.health) > half:
		return
	_has_fired = true
	_trigger()


func _trigger() -> void:
	if not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	if _bearer.status_handler:
		var muscle: MuscleStatus = MUSCLE_STATUS.duplicate()
		muscle.stacks = MUSCLE_GAIN
		_bearer.status_handler.add_status(muscle)
	_bearer.stats.cards_per_turn += EXTRA_DRAW
	status_changed.emit()


func _exit_tree() -> void:
	if _bound_check and Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.disconnect(_bound_check)
