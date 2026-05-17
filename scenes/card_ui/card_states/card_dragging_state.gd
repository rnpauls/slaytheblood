extends CardState

const DRAG_MINIMUM_THRESHOLD := 0.05
# Mouse must travel this far outside the hand rect to arm the
# re-entry-cancels-drag behavior. Prevents a small wobble at pickup from
# instantly cancelling the drag the player just started.
const EXIT_MARGIN := 50.0

@onready var hand: Hand = get_parent().get_parent().get_parent()

var minimum_drag_time_elapsed := false
var hand_rect: Rect2
var outer_rect: Rect2
var has_exited_hand := false
var pitch_zone: PitchZone

func enter() ->void:
	_log("DRAGGING entered (threshold=%.3fs)" % DRAG_MINIMUM_THRESHOLD)
	card_ui.reparent(card_ui.hover_overlay)
	card_ui.is_hovered = false
	card_ui.card_render.card_visuals.panel.set("theme_override_styles/panel", card_ui.DRAG_STYLEBOX)

	hand_rect = hand.get_global_rect()
	outer_rect = hand_rect.grow(EXIT_MARGIN)
	has_exited_hand = false
	pitch_zone = _resolve_pitch_zone()

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
	var mpos := card_ui.get_global_mouse_position()

	if mouse_motion:
		if not has_exited_hand and not outer_rect.has_point(mpos):
			has_exited_hand = true
			_log("DRAGGING: exited hand area (cancel armed)")
		elif has_exited_hand and hand_rect.has_point(mpos):
			_log("DRAGGING: re-entered hand → BASE")
			card_ui.accept_event()
			transition_requested.emit(self, CardState.State.BASE)
			return

	if single_targeted and mouse_motion and card_ui.targets.size() > 0:
		_log("DRAGGING: single_targeted with %d targets → AIMING" % card_ui.targets.size())
		transition_requested.emit(self, CardState.State.AIMING)

	if mouse_motion:
		card_ui.global_position = mpos - card_ui.pivot_offset

	if cancel:
		_log("DRAGGING: cancel (rmb) → BASE")
		card_ui.accept_event()
		transition_requested.emit(self, CardState.State.BASE)
	elif confirm and minimum_drag_time_elapsed:
		if pitch_zone and pitch_zone.contains_point(mpos):
			_log("DRAGGING: confirm in PitchZone → PITCHED")
			card_ui.accept_event()
			transition_requested.emit(self, CardState.State.PITCHED)
		else:
			_log("DRAGGING: confirm (threshold elapsed, targets=%d) → RELEASED" % card_ui.targets.size())
			card_ui.accept_event()
			transition_requested.emit(self, CardState.State.RELEASED)
	elif confirm and not minimum_drag_time_elapsed:
		_log("DRAGGING: confirm DROPPED (threshold not yet elapsed, %.3fs window)" % DRAG_MINIMUM_THRESHOLD)

func _resolve_pitch_zone() -> PitchZone:
	if not hand:
		return null
	var bu := hand.get_parent() as BattleUI
	if not bu:
		return null
	return bu.get_node_or_null("%PitchZone") as PitchZone
