extends CardState

const MOTION_THRESHOLD := 8.0

var motion_accumulator := Vector2.ZERO

func enter() ->void:
	_log("CLICKED entered")
	card_ui.drop_point_detector.monitoring = true
	card_ui.original_index = card_ui.get_index()
	motion_accumulator = Vector2.ZERO

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		motion_accumulator += event.relative
		if motion_accumulator.length() > MOTION_THRESHOLD:
			_log("CLICKED on_input: motion %.1fpx > %.1f → DRAGGING" % [motion_accumulator.length(), MOTION_THRESHOLD])
			transition_requested.emit(self, CardState.State.DRAGGING)
	elif event is InputEventMouseButton and event.is_action_released("left_mouse"):
		_log("CLICKED on_input: LMB released without drag (motion=%.1fpx) → DRAGGING (sticky)" % motion_accumulator.length())
		transition_requested.emit(self, CardState.State.DRAGGING)
	elif event is InputEventMouseButton:
		_log("CLICKED on_input: mouse button (button=%d, pressed=%s) — no transition" % [event.button_index, event.pressed])

func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_log("CLICKED on_gui_input: mouse button (button=%d, pressed=%s)" % [event.button_index, event.pressed])
