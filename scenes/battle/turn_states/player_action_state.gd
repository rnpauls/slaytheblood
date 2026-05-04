# Hand is live; player plays cards, pitches, blocks, etc. All of that
# machinery lives elsewhere (CardStateMachine, hand.gd, weapon handlers)
# and is driven by per-card signals on Events. The turn SM doesn't try
# to track those — it just waits for the end-turn button to fire
# Events.player_end_phase_started, then hands off to PLAYER_EOT.
class_name PlayerActionState
extends TurnState


func enter() -> void:
	Events.player_end_phase_started.connect(_on_end_phase_started)


func exit() -> void:
	if Events.player_end_phase_started.is_connected(_on_end_phase_started):
		Events.player_end_phase_started.disconnect(_on_end_phase_started)


func _on_end_phase_started() -> void:
	_request(State.PLAYER_EOT)
