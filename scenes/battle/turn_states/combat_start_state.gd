# Initial state. Battle.start_battle() is the trigger that drives
# combat setup — this state just waits for the existing setup chain to
# finish (signaled by player_initial_hand_drawn) and hands off to
# PLAYER_ACTION.
#
# Note: on the first turn, the START_OF_TURN cascade is already run as
# part of player_handler.start_battle() → start_turn(), so we skip
# PLAYER_SOT and go straight to PLAYER_ACTION. Subsequent turns enter
# PLAYER_SOT explicitly from ENEMY_EOT.
class_name CombatStartState
extends TurnState


func enter() -> void:
	Events.player_initial_hand_drawn.connect(_on_initial_hand_drawn)
	_arm_watchdog(State.PLAYER_ACTION)


func exit() -> void:
	if Events.player_initial_hand_drawn.is_connected(_on_initial_hand_drawn):
		Events.player_initial_hand_drawn.disconnect(_on_initial_hand_drawn)
	_disarm_watchdog()


func _on_initial_hand_drawn() -> void:
	_request(State.PLAYER_ACTION)
