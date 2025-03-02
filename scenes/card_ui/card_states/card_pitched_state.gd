extends CardState

func enter() -> void:
	
	#played = false
	#if not card_ui.targets.is_empty():
		#played = true
	card_ui.pitch()
	Events.tooltip_hide_requested.emit()

func post_enter() -> void:
	transition_requested.emit(self, CardState.State.BASE)
