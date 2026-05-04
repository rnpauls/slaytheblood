# Drives end-of-turn cleanup. enter() calls player_handler.end_turn(),
# which kicks the existing cascade:
#   relics(EOT) → _on_relics_activated → apply EOT statuses
#   → _on_statuses_applied → end_turn_cleanup
#   → reset mana / AP=0 / draw back up to cards_per_turn
#   → tween finishes → Events.player_hand_drawn
#
# We listen for player_hand_drawn as the "EOT cascade is done" signal
# and transition to ENEMY_SOT.
#
# (BattleUI also emits Events.player_turn_ended off player_hand_drawn,
# but with the connect in Battle._ready disabled, that signal becomes
# a no-op fanout. Left in place for pass 1; can be removed in pass 2.)
class_name PlayerEndOfTurnState
extends TurnState


func enter() -> void:
	Events.player_hand_drawn.connect(_on_hand_drawn)
	player_handler.end_turn()


func exit() -> void:
	if Events.player_hand_drawn.is_connected(_on_hand_drawn):
		Events.player_hand_drawn.disconnect(_on_hand_drawn)


func _on_hand_drawn() -> void:
	_request(State.ENEMY_SOT)
