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
	# When the card was actually played, card_ui.play() has already reparented
	# it to the discard pile. Transitioning to BASE here would call return_to_hand
	# and yank it back, which both leaves a ghost in hand AND causes the discard
	# pile to spawn a phantom anonymous card to fill the resource/visual gap.
	if not played:
		transition_requested.emit(self, CardState.State.BASE)

func _release_and_play() -> void:
	played = true
	card_ui.play()
	Events.tooltip_hide_requested.emit()
