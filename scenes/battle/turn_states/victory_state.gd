# Terminal state. Entered via TurnStateMachine.force_transition() from
# Battle._on_enemies_child_order_changed when the enemy count hits 0.
#
# Pass 1: the existing Battle._on_relics_activated handler still
# activates END_OF_COMBAT relics and emits battle_over_screen_requested
# with the win panel. This state just exists as a terminal marker so
# any other in-flight transitions (e.g. an enemy declaring an attack
# the same frame the last one died) become no-ops — once we're here,
# the SM ignores transition_requested signals from previous states.
class_name VictoryState
extends TurnState


func enter() -> void:
	print_debug("[TurnSM] Victory")
