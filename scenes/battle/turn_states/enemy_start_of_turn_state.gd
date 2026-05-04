# Pass 1 scope: this state covers the moment the enemy phase begins.
# It calls enemy_handler.start_turn() (which used to be wired through
# Events.player_turn_ended.connect(enemy_handler.start_turn) in
# Battle._ready) and then defers a transition to ENEMY_ACTING.
#
# The actual per-enemy SOT statuses → AI plan → declare cascade still
# lives inside EnemyHandler in pass 1. Pass 2 will hoist that loop out
# of EnemyHandler and into this state + ENEMY_ACTING + ENEMY_EOT, with
# real per-enemy granularity.
#
# call_deferred is used for the transition because we don't want to
# fire transition_requested while we're still inside enter() — the SM
# would try to call exit() before the state's enter() has fully run.
class_name EnemyStartOfTurnState
extends TurnState


func enter() -> void:
	enemy_handler.start_turn()
	# Pass 1: hand off immediately. The internal cascade in EnemyHandler
	# carries the phase forward from here.
	_request.call_deferred(State.ENEMY_ACTING)
