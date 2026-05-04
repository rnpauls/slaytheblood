# Terminal state. Entered via TurnStateMachine.force_transition() from
# Battle._on_player_died.
#
# Pass 1: Battle._on_player_died still emits
# battle_over_screen_requested and calls SaveGame.delete_data(). This
# state exists as a terminal marker so any in-flight transitions
# triggered the same frame become no-ops.
class_name DefeatState
extends TurnState


func enter() -> void:
	print_debug("[TurnSM] Defeat")
