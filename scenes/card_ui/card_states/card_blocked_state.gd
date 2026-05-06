extends CardState

func enter() -> void:
	card_ui.block()
	Events.tooltip_hide_requested.emit()

# No post_enter transition: card_ui.block() has already handed the visual off
# to the discard pile. Same reasoning as card_released_state.gd.
