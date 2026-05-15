## Bloody Sap: Cursed Treant passive. Every time the bearer actually takes
## damage (post-block, > 0), they gain 1 stack of Muscle for the rest of the
## battle. The longer the fight drags, the harder the Treant hits — but a
## block-heavy player can deny stacks by absorbing the swings.
##
## Uses combatant_damaged (only fires on landed damage), not combatant_attacked,
## so blocked hits don't ramp the Treant.
class_name BloodySapStatus
extends Status

const MUSCLE_GAIN := 1
const MUSCLE_STATUS := preload("res://statuses/muscle.tres")

var _bearer: Combatant = null
var _bound_check: Callable


func get_tooltip() -> String:
	return tooltip


func initialize_status(target: Node) -> void:
	if target == null:
		return
	_bearer = target as Combatant
	_bound_check = _on_combatant_damaged
	if not Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.connect(_bound_check)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_combatant_damaged(victim: Node, _attacker: Node, damage: int) -> void:
	if victim != _bearer or damage <= 0:
		return
	if not is_instance_valid(_bearer) or _bearer.status_handler == null:
		return
	var dup: MuscleStatus = MUSCLE_STATUS.duplicate()
	dup.stacks = MUSCLE_GAIN
	_bearer.status_handler.add_status(dup)


func _exit_tree() -> void:
	if _bound_check and Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.disconnect(_bound_check)
