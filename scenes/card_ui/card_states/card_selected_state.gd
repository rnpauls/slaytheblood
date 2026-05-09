extends CardState

const SELECT_GLOW_TINT := Color(0.4, 0.85, 1.6, 1.0)
const SELECT_Z := 25

func enter() -> void:
	card_ui.select()
	card_ui.z_index = SELECT_Z
	card_ui.card_render.set_glow(true)
	card_ui.card_render.glow_panel.modulate = SELECT_GLOW_TINT
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.SELECTED_STYLEBOX)

func exit() -> void:
	card_ui.deselect()
	card_ui.card_render.glow_panel.modulate = Color.WHITE
	card_ui.z_index = 0
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_STYLEBOX)
	if card_ui is PlayerCardUI:
		card_ui.card_render.set_glow((card_ui as PlayerCardUI).playable)

func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		transition_requested.emit(self, CardState.State.BASE)

func on_mouse_entered() -> void:
	if card_ui.is_hovered:
		return
	card_ui.is_hovered = true
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()

	card_ui.original_parent = card_ui.get_parent()
	card_ui.original_index = card_ui.get_index()

	card_ui.scale = Vector2.ONE * card_ui.hover_scale
	card_ui.rotation = 0
	var screen_bottom := card_ui.get_viewport_rect().size.y - card_ui.size.y
	var new_y = clampf(card_ui.global_position.y, 0, screen_bottom)
	card_ui.global_position.y = new_y
	card_ui.z_index = SELECT_Z

	card_ui.request_tooltip()
	card_ui.card_hovered.emit(card_ui)


func on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
	if not card_ui.is_hovered:
		return
	card_ui.is_hovered = false
	card_ui.z_index = SELECT_Z
	card_ui.return_to_hand()

	card_ui.card_unhovered.emit(card_ui)
