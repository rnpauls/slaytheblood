# Drives outer turn-phase transitions in combat. Modeled on
# CardStateMachine — same states-dict + transition_requested pattern.
#
# Pass 1 scope: the SM owns the boundaries between player turn / enemy
# turn / victory / defeat. The internal cascades inside each phase
# (relics → statuses → action_phase_started, etc.) are still driven by
# the existing handler signal chains; states just listen for the
# right "phase-done" signal and transition.
#
# Pass 2 will pull the per-enemy SOT/ACTING/EOT loop out of
# EnemyHandler and into ENEMY_SOT / ENEMY_ACTING / ENEMY_EOT states.
# In pass 1 those three states exist but ENEMY_SOT immediately calls
# enemy_handler.start_turn() and hands off to ENEMY_ACTING, which
# waits for Events.enemy_phase_ended (the existing whole-phase signal).
class_name TurnStateMachine
extends Node

signal state_changed(state: TurnState.State)

var current_state: TurnState
var states := {}
var initial_state_key: TurnState.State = TurnState.State.COMBAT_START


# Battle calls this after it has built up its handler refs. We grab the
# handlers off Battle and inject them into every state so states don't
# have to know about the scene tree.
func init(p_battle: Battle) -> void:
	for child in get_children():
		if child is TurnState:
			states[child.state] = child
			child.battle = p_battle
			child.player_handler = p_battle.player_handler
			child.enemy_handler = p_battle.enemy_handler
			child.relics = p_battle.relics
			child.transition_requested.connect(_on_transition_requested)

	if states.has(initial_state_key):
		current_state = states[initial_state_key]
		print_debug("[TurnSM] enter ", _name_of(initial_state_key))
		current_state.enter()
		state_changed.emit(initial_state_key)


# Used for terminal forces (player death, all enemies dead). Bypasses
# the from-state check so we can interrupt any phase.
func force_transition(to: TurnState.State) -> void:
	if not states.has(to):
		push_warning("TurnStateMachine.force_transition: no state for %s" % to)
		return

	if current_state and current_state.state == to:
		return

	if current_state:
		current_state.exit()

	current_state = states[to]
	print_debug("[TurnSM] force → ", _name_of(to))
	current_state.enter()
	state_changed.emit(to)


func _on_transition_requested(from: TurnState, to: TurnState.State) -> void:
	# Guard against stale signal callbacks from a state we've already
	# exited (can happen if exit() didn't disconnect everything).
	if from != current_state:
		return

	if not states.has(to):
		push_warning("TurnStateMachine: no state for %s" % to)
		return

	current_state.exit()
	current_state = states[to]
	print_debug("[TurnSM] ", _name_of(from.state), " → ", _name_of(to))
	current_state.enter()
	state_changed.emit(to)


func _name_of(s: TurnState.State) -> String:
	return TurnState.State.keys()[s]
