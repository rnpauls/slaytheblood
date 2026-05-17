class_name PitchZone
extends Control

const FADE_DURATION := 0.15
const DISABLED_MODULATE := Color(0.4, 0.4, 0.4, 0.5)

@onready var panel: PanelContainer = %Panel
@onready var mana_label: Label = %ManaLabel

var current_card_ui: CardUI
var can_pitch: bool = false
var _tween: Tween
var _base_stylebox: StyleBoxFlat
var _hide_pending := false


func _ready() -> void:
	hide()
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := panel.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		_base_stylebox = sb
	# Listen to both drag and aim so the zone stays visible across the
	# DRAGGING → AIMING transition that single-targeted cards undergo when
	# the mouse passes over an enemy.
	Events.card_drag_started.connect(_on_drag_or_aim_started)
	Events.card_drag_ended.connect(_on_drag_or_aim_ended)
	Events.card_aim_started.connect(_on_drag_or_aim_started)
	Events.card_aim_ended.connect(_on_drag_or_aim_ended)


func contains_point(p: Vector2) -> bool:
	return visible and can_pitch and get_global_rect().has_point(p)


func _on_drag_or_aim_started(origin: Node) -> void:
	if not (origin is CardUI) or not _is_player_card(origin):
		return
	# Cancel any pending hide queued by a sibling end-signal that fired
	# in the same frame (e.g. card_drag_ended right before card_aim_started).
	_hide_pending = false
	current_card_ui = origin
	can_pitch = _compute_can_pitch(origin)

	mana_label.text = "+%d" % origin.card.pitch
	_apply_pitch_color(origin.card.pitch)

	modulate = Color.WHITE if can_pitch else DISABLED_MODULATE
	modulate.a = 0.0
	show()

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)


func _on_drag_or_aim_ended(origin: Node) -> void:
	if not (origin is CardUI):
		return
	if current_card_ui != origin:
		return
	# Defer so a follow-up start (DRAGGING → AIMING fires both end-then-start
	# in the same frame) can cancel the hide.
	_hide_pending = true
	call_deferred("_apply_pending_hide", origin)


func _apply_pending_hide(origin: CardUI) -> void:
	if not _hide_pending:
		return
	if current_card_ui != origin:
		return
	_hide_pending = false
	current_card_ui = null
	can_pitch = false
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(hide)


func _apply_pitch_color(pitch: int) -> void:
	if not _base_stylebox:
		return
	var tinted := _base_stylebox.duplicate() as StyleBoxFlat
	tinted.bg_color = _pitch_color(pitch)
	panel.add_theme_stylebox_override("panel", tinted)


func _pitch_color(pitch: int) -> Color:
	match pitch:
		1: return Constants.RED_PITCH
		2: return Constants.YELLOW_PITCH
		3: return Constants.BLUE_PITCH
		_: return Color.WHITE


func _is_player_card(card_ui: CardUI) -> bool:
	return card_ui and card_ui.card and card_ui.card.owner is Player


func _compute_can_pitch(card_ui: CardUI) -> bool:
	if card_ui.card.disable_pitch:
		return false
	if card_ui.disabled:
		return false
	var hand_node := _find_hand(card_ui)
	if hand_node:
		if hand_node.is_selecting or hand_node.is_blocking:
			return false
		if hand_node.player and hand_node.player.status_handler:
			if hand_node.player.status_handler.has_status("stunned"):
				return false
	return true


func _find_hand(card_ui: CardUI) -> Hand:
	var p: Node = card_ui.original_parent if card_ui.original_parent else card_ui.get_parent()
	while p:
		if p is Hand:
			return p
		p = p.get_parent()
	return null
