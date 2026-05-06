extends CardState

func enter() -> void:
	card_ui.pitch()
	Events.tooltip_hide_requested.emit()

# No post_enter transition: card_ui.pitch() has already handed the visual off
# to the draw pile. Transitioning to BASE would return_to_hand and break the
# handoff (see card_released_state.gd for the same fix).
