extends CardState

var played: bool

func enter() -> void:
	played = false
	if not card_ui.card.is_single_targeted():
		_release_and_play()
	elif not card_ui.targets.is_empty():
		#print(card_ui.targets[0].get_class())
		if card_ui.targets[0] is Enemy:
			_release_and_play()

func post_enter() -> void:
	transition_requested.emit(self, CardState.State.BASE)

func _release_and_play() -> void:
	played = true
	card_ui.play()
	Events.tooltip_hide_requested.emit()
