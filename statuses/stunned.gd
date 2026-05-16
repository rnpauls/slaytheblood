class_name StunnedStatus
extends Status

## Bearer cannot play, pitch, or block while present. Gates live in
## card_base_state.gd (player) and enemy_ai.gd (enemy).
##
## Expires at the end of the bearer's own next turn (inverse of intimidate,
## which expires on the opposite side's turn end) so the bearer loses one full
## turn of agency.

var _target_ref: Node = null
var _bound_apply: Callable


func initialize_status(target: Node) -> void:
	_target_ref = target
	_bound_apply = apply_status.bind(target)
	if target is Enemy:
		Events.enemy_phase_ended.connect(_bound_apply)
	else:
		Events.player_turn_ended.connect(_bound_apply)


func apply_status(_target) -> void:
	status_applied.emit(self)


func _exit_tree() -> void:
	if _bound_apply:
		if _target_ref is Enemy:
			if Events.enemy_phase_ended.is_connected(_bound_apply):
				Events.enemy_phase_ended.disconnect(_bound_apply)
		else:
			if Events.player_turn_ended.is_connected(_bound_apply):
				Events.player_turn_ended.disconnect(_bound_apply)
