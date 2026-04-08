extends CardState

var played: bool

func enter() -> void:
	
	played = false
	if not card_ui.targets.is_empty():
		print(card_ui.targets[0].get_class())
		if card_ui.targets[0] is Enemy:
			played = true
			card_ui.play()
			Events.tooltip_hide_requested.emit()

func post_enter() -> void:
	transition_requested.emit(self, CardState.State.BASE)
