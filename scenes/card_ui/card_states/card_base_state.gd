extends CardState

@onready var hand: Hand = get_parent().get_parent().get_parent()

func enter() ->void:
	if not card_ui.is_node_ready():
		await card_ui.ready
	card_ui.return_to_hand()
	card_ui.is_hovered = false
	card_ui.z_index = 0
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_STYLEBOX)
	card_ui.pivot_offset = card_ui.size/2
	
	Events.tooltip_hide_requested.emit()

func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse") and hand.is_selecting:
		_log("BASE on_gui_input: LMB (is_selecting=true) → SELECTED")
		transition_requested.emit(self, CardState.State.SELECTED)
	if event.is_action_pressed("left_mouse") and hand.is_blocking:
		var player: Player = hand.player
		var is_intimidated := player and card_ui.card in player.intimidated_cards
		if not is_intimidated and not card_ui.card.disable_defense:
			_log("BASE on_gui_input: LMB (is_blocking=true) → BLOCKED")
			transition_requested.emit(self, CardState.State.BLOCKED)
	if event.is_action_pressed("right_mouse"):
		_log("BASE on_gui_input: RMB → PITCHED")
		transition_requested.emit(self, CardState.State.PITCHED)
	if not card_ui.playable or card_ui.disabled:
		if event.is_action_pressed("left_mouse"):
			_log("BASE on_gui_input: LMB IGNORED (playable=%s, disabled=%s)" % [card_ui.playable, card_ui.disabled])
		return
	if event.is_action_pressed("left_mouse"):
		_log("BASE on_gui_input: LMB → CLICKED (playable=%s, disabled=%s)" % [card_ui.playable, card_ui.disabled])
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		transition_requested.emit(self, CardState.State.CLICKED)

func on_mouse_entered() -> void:
	if card_ui.is_hovered: 
		return
	card_ui.is_hovered = true
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()
	
	# Remember where it was in the hand
	card_ui.original_parent = card_ui.get_parent()
	card_ui.original_index = card_ui.get_index()
	
	card_ui.scale = Vector2.ONE*card_ui.hover_scale
	card_ui.rotation = 0
	#Get new y clamped
	var screen_bottom:= card_ui.get_viewport_rect().size.y - card_ui.size.y
	var new_y = clampf(card_ui.global_position.y, 0, screen_bottom)
	card_ui.global_position.y = new_y
	card_ui.z_index = 20   # Bring way to front
	#card_ui.tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#card_ui.tween.tween_property(card_ui, "scale", Vector2(card_ui.hover_scale, card_ui.hover_scale), card_ui.tween_duration)
	#card_ui.tween.parallel().tween_property(card_ui, "global_position:y", new_y, card_ui.tween_duration)
	
	card_ui.request_tooltip()
	card_ui.card_hovered.emit(card_ui)
	if not card_ui.playable or card_ui.disabled:
		return

	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.HOVER_STYLEBOX)


func on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
	if not card_ui.is_hovered: 
		return
	card_ui.is_hovered = false
	card_ui.z_index=0
	card_ui.return_to_hand()
	
	card_ui.card_unhovered.emit(card_ui)
	if not card_ui.playable or card_ui.disabled:
		return
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_STYLEBOX)
	
