# Drives end-of-turn cleanup. enter() calls player_handler.end_turn(),
# which kicks the existing cascade:
#   relics(EOT) → _on_relics_activated → apply EOT statuses
#   → _on_statuses_applied → end_turn_cleanup
#   → reset mana / AP=0 / draw back up to cards_per_turn
#   → tween finishes → Events.player_hand_drawn
#
# We listen for player_hand_drawn as the "EOT cascade is done" signal
# and transition to ENEMY_SOT. (player_turn_ended is also emitted off
# player_hand_drawn by BattleUI — kept because status effects like
# intimidated / poison_tip / empowered hook into it.)
class_name PlayerEndOfTurnState
extends TurnState


func enter() -> void:
	Events.player_hand_drawn.connect(_on_hand_drawn)
	_arm_watchdog(State.ENEMY_SOT)
	player_handler.end_turn()


func exit() -> void:
	if Events.player_hand_drawn.is_connected(_on_hand_drawn):
		Events.player_hand_drawn.disconnect(_on_hand_drawn)
	_disarm_watchdog()


func _on_hand_drawn() -> void:
	_request(State.ENEMY_SOT)
