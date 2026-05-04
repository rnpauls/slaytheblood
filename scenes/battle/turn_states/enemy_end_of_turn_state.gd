# Tail end of the enemy phase. Preserves the side effect that used to
# live in Battle._on_enemy_phase_ended pre-refactor:
#
#   func _on_enemy_phase_ended() -> void:
#       player_handler.start_turn()         # → moved to PLAYER_SOT.enter()
#       enemy_handler.reset_enemy_actions() # → handled here
#
# After resetting intents, defer a transition to PLAYER_SOT for the
# next round.
class_name EnemyEndOfTurnState
extends TurnState


func enter() -> void:
	enemy_handler.reset_enemy_actions()
	_request.call_deferred(State.PLAYER_SOT)
