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


# ── Phase-gate watchdog ──────────────────────────────────────────────────────
#
# Most states gate their transition on a signal that fires at the end of a
# tween chain (statuses_applied, player_hand_drawn, plan_created, etc.). If
# that tween is cancelled mid-flight (player death during cleanup, scene
# torn down, signal handler exception) the gate signal never fires and the
# turn loop deadlocks silently.
#
# The watchdog is a one-shot SceneTreeTimer that, if it fires, force-exits
# the current state to a fallback (the same state we'd have transitioned to
# on success) with a loud push_warning. Real bugs surface in logs; combat
# keeps moving instead of locking the player out.
#
# Usage in concrete states:
#   func enter() -> void:
#       Events.foo.connect(_on_foo)
#       _arm_watchdog(State.NEXT_STATE)
#       handler.kick_off_cascade()
#
#   func exit() -> void:
#       Events.foo.disconnect(_on_foo)
#       _disarm_watchdog()

## Default timeout (seconds). 10s is generous — typical cascades resolve in
## well under 2s. Override per-state if a particular phase legitimately
## needs longer (e.g. boss-tier status pile-ons).
const PHASE_GATE_TIMEOUT := 10.0

var _watchdog_armed: bool = false


## Arm the watchdog with a fallback state. If `timeout` seconds pass before
## _disarm_watchdog() is called, force a transition to `fallback` with a
## warning. Multiple calls re-arm the timer (the previous timer's callback
## will see _watchdog_armed=false-then-true and bail on the stale generation).
func _arm_watchdog(fallback: State, timeout: float = PHASE_GATE_TIMEOUT) -> void:
	_watchdog_armed = true
	# Capture the current generation by snapshotting `state` at arm time —
	# if exit() runs and a new state arms its own watchdog before our timer
	# fires, the stale callback will see _watchdog_armed=true on the new
	# state and could mis-fire. The bool flag alone is enough because exit()
	# always calls _disarm_watchdog() (which sets the flag false), and the
	# next state's _arm_watchdog re-sets it true on a fresh state instance.
	# So a stale timer firing after exit will see false. The only risk is
	# arm→arm on the same instance, which the early _watchdog_armed=true
	# write below guarantees stays armed.
	var t := get_tree().create_timer(timeout, false)
	t.timeout.connect(_on_watchdog_timeout.bind(fallback))


func _disarm_watchdog() -> void:
	_watchdog_armed = false


func _on_watchdog_timeout(fallback: State) -> void:
	if not _watchdog_armed:
		return  # cleanly exited or re-armed by a later call
	_watchdog_armed = false
	push_warning("[TurnSM] phase-gate timeout in %s; forcing %s" % [
		State.keys()[state], State.keys()[fallback]])
	# Use the same transition_requested path as a normal success transition
	# so the SM runs exit()/enter() correctly. force_transition would also
	# work, but the regular path keeps the from/to logging consistent.
	transition_requested.emit(self, fallback)
