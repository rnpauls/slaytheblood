# Hand is live; player plays cards, pitches, blocks, etc. All of that
# machinery lives elsewhere (CardStateMachine, hand.gd, weapon handlers)
# and is driven by per-card signals on Events. The turn SM doesn't try
# to track those — it just waits for the end-turn button to fire
# Events.player_end_phase_started, then hands off to PLAYER_EOT.
class_name PlayerActionState
extends TurnState


func enter() -> void:
	# Stunned: skip the action phase entirely — never arm the END button, never
	# wait for input. Deferred so the SM finishes entering PLAYER_ACTION before
	# transitioning out. We bypass Events.player_end_phase_started (which carries
	# "user clicked END" semantics BattleUI button logic listens to) and request
	# the transition directly — _on_end_phase_started just does the same.
	if _player_is_stunned():
		call_deferred("_request", State.PLAYER_EOT)
		return
	Events.player_end_phase_started.connect(_on_end_phase_started)


func exit() -> void:
	if Events.player_end_phase_started.is_connected(_on_end_phase_started):
		Events.player_end_phase_started.disconnect(_on_end_phase_started)


func _on_end_phase_started() -> void:
	_request(State.PLAYER_EOT)


func _player_is_stunned() -> bool:
	var player := player_handler.player if player_handler else null
	return player and player.status_handler and player.status_handler.has_status("stunned")
