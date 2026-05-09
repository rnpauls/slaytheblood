extends CardState

const SELECT_TINT := Color(1.6, 1.45, 0.55, 1.0)
const TWEEN_DURATION := 0.15

func enter() -> void:
	card_ui.select()
	card_ui.z_index = 25
	card_ui.card_render.set_glow(true)
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.SELECTED_STYLEBOX)

	var t := card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card_ui.card_render, "modulate", SELECT_TINT, TWEEN_DURATION)

func exit() -> void:
	card_ui.deselect()
	card_ui.card_render.modulate = Color.WHITE
	card_ui.z_index = 0
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_STYLEBOX)
	# Restore the playability glow (selection forces it on; reset to actual state).
	if card_ui is PlayerCardUI:
		card_ui.card_render.set_glow((card_ui as PlayerCardUI).playable)

func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		transition_requested.emit(self, CardState.State.BASE)

func on_mouse_entered() -> void:
	if card_ui.is_hovered:
		return
	card_ui.is_hovered = true

	card_ui.original_parent = card_ui.get_parent()
	card_ui.original_index = card_ui.get_index()

	card_ui.request_tooltip()
	card_ui.card_hovered.emit(card_ui)


func on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
	if not card_ui.is_hovered:
		return
	card_ui.is_hovered = false

	card_ui.card_unhovered.emit(card_ui)
