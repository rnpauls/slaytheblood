# Replaces the implicit "enemy_phase_ended → player_handler.start_turn"
# connect that used to live in Battle._ready (line 22 pre-refactor).
#
# enter() kicks the existing START_OF_TURN cascade by calling
# player_handler.start_turn(). That cascade emits
# Events.player_action_phase_started when statuses finish applying;
# we listen for that and transition to PLAYER_ACTION.
class_name PlayerStartOfTurnState
extends TurnState


func enter() -> void:
	Events.player_action_phase_started.connect(_on_action_phase_started)
	player_handler.start_turn()


func exit() -> void:
	if Events.player_action_phase_started.is_connected(_on_action_phase_started):
		Events.player_action_phase_started.disconnect(_on_action_phase_started)


func _on_action_phase_started() -> void:
	_request(State.PLAYER_ACTION)
