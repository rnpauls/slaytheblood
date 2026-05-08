# Terminal state. Entered via TurnStateMachine when both sides are out of
# usable cards at the start of the player's turn. The stalemate panel
# (BattleOverPanel.Type.STALEMATE) is shown directly by the trigger
# in PlayerStartOfTurnState; this state just exists as a terminal
# marker so any in-flight transitions become no-ops once we're here.
class_name StalemateState
extends TurnState


func enter() -> void:
	print_debug("[TurnSM] Stalemate")
