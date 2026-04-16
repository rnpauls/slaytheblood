extends CardState

@onready var hand: Hand = get_parent().get_parent().get_parent()
var is_hovered:=false

func enter() ->void:
	if not card_ui.is_node_ready():
		await card_ui.ready
	#print("entering base state")
	card_ui.return_to_hand()
	card_ui.is_hovered = false
	card_ui.z_index = 0
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_STYLEBOX)
	card_ui.pivot_offset = card_ui.size/2
	
	Events.tooltip_hide_requested.emit()

func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse") and hand.is_selecting:
		transition_requested.emit(self, CardState.State.SELECTED)
	if event.is_action_pressed("left_mouse") and hand.is_blocking:
		transition_requested.emit(self, CardState.State.BLOCKED)
	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, CardState.State.PITCHED)
	if not card_ui.playable or card_ui.disabled:
		return
	if event.is_action_pressed("left_mouse"):
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		transition_requested.emit(self, CardState.State.CLICKED)

func on_mouse_entered() -> void:
	if is_hovered: 
		#print("mouse entered but already hovered")
		return
	is_hovered = true
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()
	
	# 1. Capture current global position BEFORE reparenting
	#card_ui.original_global_pos = card_ui.global_position
	
	# 2. Remember where it was in the hand
	card_ui.original_parent = card_ui.get_parent()
	card_ui.original_index = card_ui.get_index()
	
	# 3. Reparent to overlay
	#card_ui.original_parent.remove_child(self)
	#card_ui.hover_overlay.add_child(self)
	#card_ui.reparent(card_ui.hover_overlay)
	#print("Reparented to HoverOverlay: ", card_ui.get_parent().name)
	
	# 4. Immediately put it back at the exact same screen position
	#card_ui.global_position = card_ui.original_global_pos
	card_ui.rotation = 0
	
	#Get new y clamped
	var screen_bottom:= card_ui.get_viewport_rect().size.y - card_ui.size.y
	var new_y = clampf(card_ui.global_position.y, 0, screen_bottom)
	#print(new_y)
	# 5. Start the nice tween
	#print("mouse entered")
	card_ui.scale = Vector2.ONE*card_ui.hover_scale
	card_ui.global_position.y = new_y
	#print(card_ui)
	#print(card_ui.global_position)
	
	#card_ui.tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#card_ui.tween.tween_property(card_ui, "scale", Vector2(card_ui.hover_scale, card_ui.hover_scale), card_ui.tween_duration)
	#card_ui.tween.parallel().tween_property(card_ui, "global_position:y", new_y, card_ui.tween_duration)
	
	card_ui.z_index = 20   # Bring way to front
	
	
	#card_ui.request_tooltip()
	card_ui.card_hovered.emit(card_ui)
	if not card_ui.playable or card_ui.disabled:
		return
	
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.HOVER_STYLEBOX)
	

func on_mouse_exited() -> void:
	#Events.tooltip_hide_requested.emit()
	if not is_hovered: 
		#print("mouse exited but its not hovered")
		return
	is_hovered = false
	card_ui.z_index=0
	#print("mouse exit return to hand")
	card_ui.return_to_hand()
	
	card_ui.card_unhovered.emit(card_ui)   # tell hand we are hovered
	if not card_ui.playable or card_ui.disabled:
		return
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_STYLEBOX)
	
