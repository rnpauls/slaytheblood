extends CardState

func enter() -> void:
	
	#played = false
	#if not card_ui.targets.is_empty():
		#played = true
	card_ui.select()
	card_ui.card_visuals.panel.set("theme_override_styles/panel", card_ui.SELECTED_STYLEBOX)
	#Events.tooltip_hide_requested.emit()

func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		card_ui.deselect()
		transition_requested.emit(self, CardState.State.BASE)
