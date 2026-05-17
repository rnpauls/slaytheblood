extends CardState

const EXIT_MARGIN := 50.0

@onready var hand: Hand = get_parent().get_parent().get_parent()

var hand_rect: Rect2
var outer_rect: Rect2
var has_exited_hand := true
var pitch_zone: PitchZone

func enter() -> void:
	_log("AIMING entered")
	card_ui.drop_point_detector.monitoring = false
	card_ui.targets.clear()
	var offset := Vector2(card_ui.original_parent.size.x/2, -card_ui.size.y/4)
	offset.x -= card_ui.size.x/2
	card_ui.animate_to_position(card_ui.original_parent.global_position + offset, 0.2)

	hand_rect = hand.get_global_rect()
	outer_rect = hand_rect.grow(EXIT_MARGIN)
	# Aiming begins because the card just overlapped an enemy target, so the
	# mouse should already be well outside the hand area. Initialize from
	# current mouse position to be safe.
	has_exited_hand = not outer_rect.has_point(card_ui.get_global_mouse_position())
	pitch_zone = _resolve_pitch_zone()

	Events.card_aim_started.emit(card_ui)

func exit() -> void:
	Events.card_aim_ended.emit(card_ui)

func on_input(event: InputEvent) -> void:
	var mouse_motion := event is InputEventMouseMotion
	var rmb_cancel := event.is_action_pressed("right_mouse")
	var confirm := event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	var mpos := card_ui.get_global_mouse_position()
	var hand_reentry := false

	if mouse_motion:
		if not has_exited_hand and not outer_rect.has_point(mpos):
			has_exited_hand = true
		elif has_exited_hand and hand_rect.has_point(mpos):
			hand_reentry = true

	if rmb_cancel or hand_reentry:
		_log("AIMING: cancel (%s) → BASE" % ("rmb" if rmb_cancel else "hand_reentry"))
		card_ui.accept_event()
		transition_requested.emit(self, CardState.State.BASE)
		card_ui.targets.clear()
	elif confirm and pitch_zone and pitch_zone.contains_point(mpos):
		_log("AIMING: confirm in PitchZone → PITCHED")
		card_ui.accept_event()
		card_ui.targets.clear()
		transition_requested.emit(self, CardState.State.PITCHED)
	elif confirm and card_ui.targets.size() > 0:
		_log("AIMING: confirm with %d targets → RELEASED" % card_ui.targets.size())
		card_ui.accept_event()
		transition_requested.emit(self,CardState.State.RELEASED)

func _resolve_pitch_zone() -> PitchZone:
	if not hand:
		return null
	var bu := hand.get_parent() as BattleUI
	if not bu:
		return null
	return bu.get_node_or_null("%PitchZone") as PitchZone
