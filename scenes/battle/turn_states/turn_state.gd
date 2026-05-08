# Base class for all turn-flow states. Mirrors the pattern in
# scenes/card_ui/card_states/card_state.gd so a Godot dev familiar with
# the existing card SM can read this without surprise.
#
# A state's enter() is the one place phase-entry side effects live
# (calling handler.start_turn(), enabling hand, etc). Its exit() must
# disconnect anything enter() connected — otherwise force_transition
# (e.g. on player death) leaks dangling listeners into the next state.
class_name TurnState
extends Node

enum State {
	COMBAT_START,
	PLAYER_SOT,
	PLAYER_ACTION,
	PLAYER_EOT,
	ENEMY_SOT,
	ENEMY_ACTING,
	ENEMY_EOT,
	VICTORY,
	DEFEAT,
	STALEMATE,
}

signal transition_requested(from: TurnState, to: State)

@export var state: State

# Context refs populated by TurnStateMachine.init(). Concrete states use
# these instead of looking nodes up themselves — keeps states decoupled
# from the scene tree layout.
var battle: Battle
var player_handler: PlayerHandler
var enemy_handler: EnemyHandler
var relics: RelicHandler


func enter() -> void:
	pass


func exit() -> void:
	pass


# Convenience for concrete states. Use this in signal callbacks rather
# than emitting transition_requested manually.
func _request(to: State) -> void:
	transition_requested.emit(self, to)
