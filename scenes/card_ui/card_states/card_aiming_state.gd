extends CardState

const MOUSE_Y_SNAPBACK_THRESHOLD := 720-20

func enter() -> void:
	_log("AIMING entered")
	card_ui.drop_point_detector.monitoring = false
	card_ui.targets.clear()
	var offset := Vector2(card_ui.original_parent.size.x/2, -card_ui.size.y/4)
	offset.x -= card_ui.size.x/2
	card_ui.animate_to_position(card_ui.original_parent.global_position + offset, 0.2)

	Events.card_aim_started.emit(card_ui)

func exit() -> void:
	Events.card_aim_ended.emit(card_ui)

func on_input(event: InputEvent) -> void:
	var mouse_motion := event is InputEventMouseMotion
	var mouse_at_bottom := card_ui.get_global_mouse_position().y > MOUSE_Y_SNAPBACK_THRESHOLD

	if (mouse_motion and mouse_at_bottom) or event.is_action_pressed("right_mouse"):
		_log("AIMING: cancel (%s) → BASE" % ("rmb" if event.is_action_pressed("right_mouse") else "mouse_at_bottom"))
		card_ui.accept_event()
		transition_requested.emit(self, CardState.State.BASE)
		card_ui.targets.clear()
	elif (card_ui.targets.size() > 0) and (event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")):
		#get_viewport().set_input_as_handled()
		_log("AIMING: confirm with %d targets → RELEASED" % card_ui.targets.size())
		card_ui.accept_event()
		transition_requested.emit(self,CardState.State.RELEASED)
