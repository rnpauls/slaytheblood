extends CardState

const DRAG_MINIMUM_THRESHOLD := 0.05
var minimum_drag_time_elapsed := false
const MOUSE_Y_SNAPBACK_THRESHOLD := 720-20

func enter() ->void:
	_log("DRAGGING entered (threshold=%.3fs)" % DRAG_MINIMUM_THRESHOLD)
	card_ui.reparent(card_ui.hover_overlay)
	card_ui.is_hovered = false
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.DRAG_STYLEBOX)
	Events.card_drag_started.emit(card_ui)

	minimum_drag_time_elapsed = false
	var threshold_timer := get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)
	threshold_timer.timeout.connect(func():
		minimum_drag_time_elapsed = true
		_log("DRAGGING threshold elapsed"))

func exit() -> void:
	Events.card_drag_ended.emit(card_ui)

func on_input(event: InputEvent) -> void:
	var single_targeted := card_ui.card.is_single_targeted()
	var mouse_motion := event is InputEventMouseMotion
	var cancel = event.is_action_pressed("right_mouse")
	var confirm = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	var mouse_at_bottom := card_ui.get_global_mouse_position().y > MOUSE_Y_SNAPBACK_THRESHOLD

	if single_targeted and mouse_motion and card_ui.targets.size() > 0:
		_log("DRAGGING: single_targeted with %d targets → AIMING" % card_ui.targets.size())
		transition_requested.emit(self, CardState.State.AIMING)

	if mouse_motion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset

	if cancel or (mouse_motion and mouse_at_bottom):
		_log("DRAGGING: cancel (%s) → BASE" % ("rmb" if cancel else "mouse_at_bottom"))
		card_ui.accept_event()
		transition_requested.emit(self, CardState.State.BASE)
	elif confirm and minimum_drag_time_elapsed:
		#get_viewport().set_input_as_handled()
		_log("DRAGGING: confirm (threshold elapsed, targets=%d) → RELEASED" % card_ui.targets.size())
		card_ui.accept_event()
		transition_requested.emit(self, CardState.State.RELEASED)
	elif confirm and not minimum_drag_time_elapsed:
		_log("DRAGGING: confirm DROPPED (threshold not yet elapsed, %.3fs window)" % DRAG_MINIMUM_THRESHOLD)
