## Bloodthirst: Reaver passive. If the bearer dealt any damage on their turn,
## they gain Muscle 1 at end of turn — a slow but inexorable damage ramp that
## punishes the player for letting attacks land instead of stalling them out
## with block.
##
## Per-turn flag: combatant_damaged with attacker == bearer flips it true; the
## bearer's phase-end fires the Muscle and resets the flag.
class_name BloodthirstStatus
extends Status

const MUSCLE_GAIN := 1
const MUSCLE_STATUS := preload("res://statuses/muscle.tres")

var _bearer: Combatant = null
var _bound_track: Callable
var _bound_tick: Callable
var _dealt_damage_this_turn: bool = false


func get_tooltip() -> String:
	return tooltip


func initialize_status(target: Node) -> void:
	if target == null:
		return
	_bearer = target as Combatant
	_bound_track = _on_combatant_damaged
	if not Events.combatant_damaged.is_connected(_bound_track):
		Events.combatant_damaged.connect(_bound_track)
	_bound_tick = _on_phase_end
	if _bearer is Player:
		Events.player_turn_ended.connect(_bound_tick)
	else:
		Events.enemy_phase_ended.connect(_bound_tick)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_combatant_damaged(_victim: Node, attacker: Node, damage: int) -> void:
	if attacker == _bearer and damage > 0:
		_dealt_damage_this_turn = true


func _on_phase_end() -> void:
	if not _dealt_damage_this_turn:
		return
	_dealt_damage_this_turn = false
	if not is_instance_valid(_bearer) or _bearer.status_handler == null:
		return
	var dup: MuscleStatus = MUSCLE_STATUS.duplicate()
	dup.stacks = MUSCLE_GAIN
	_bearer.status_handler.add_status(dup)


func _exit_tree() -> void:
	if _bound_track and Events.combatant_damaged.is_connected(_bound_track):
		Events.combatant_damaged.disconnect(_bound_track)
	if _bound_tick:
		if _bearer is Player:
			if Events.player_turn_ended.is_connected(_bound_tick):
				Events.player_turn_ended.disconnect(_bound_tick)
		else:
			if Events.enemy_phase_ended.is_connected(_bound_tick):
				Events.enemy_phase_ended.disconnect(_bound_tick)
