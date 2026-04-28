class_name PlayerCardUI
extends CardUI

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_stylebox.tres")
const DRAG_STYLEBOX := preload("res://scenes/card_ui/card_dragging_stylebox.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_stylebox.tres")
const SELECTED_STYLEBOX := preload("res://scenes/card_ui/card_selected_stylebox.tres")

@export var hover_scale := 1.0
@export var tween_duration := 0.18

@onready var card_state_machine: CardStateMachine = $CardStateMachine as CardStateMachine
@onready var drop_point_detector: Area2D = %DropPointDetector
@onready var hover_overlay: CanvasLayer = get_node("/root/Run/HoverOverlay")

var playable := true : set = _set_playable
var disabled := true
var selected := false
var original_parent: Node
var original_index: int = -1
var original_global_pos: Vector2
var is_hovered := false

func _ready() -> void:
	Events.player_card_drawn.connect(_on_card_drawn)
	Events.card_aim_started.connect(_on_card_drag_or_aiming_started)
	Events.card_drag_started.connect(_on_card_drag_or_aiming_started)
	Events.card_aim_ended.connect(_on_card_drag_or_aim_ended)
	Events.card_drag_ended.connect(_on_card_drag_or_aim_ended)
	card_state_machine.init(self)

	# Player cards are interactive
	mouse_filter = Control.MOUSE_FILTER_STOP
	drop_point_detector.monitoring = true
	scale = Vector2.ONE * 0.7

	# Re-emit CardUI lifecycle signals to the old global Events (so the rest of your code doesn't break)
	played.connect(func(_c): Events.card_played.emit(card))
	pitched.connect(func(_c): Events.card_pitched.emit(card))
	sunk.connect(func(_c): Events.card_sunk.emit(card))
	blocked.connect(func(_c): Events.card_blocked.emit(card))
	discarded.connect(func(_c): Events.card_discarded.emit(card))

func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)

func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)

func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()

func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()

func return_to_hand() -> void:
	_return_to_original_parent()

func _return_to_original_parent() -> void:
	if not is_inside_tree(): return
	reparent_requested.emit(self)
	z_index = 0
	scale = Vector2.ONE * 0.7

func _on_card_drag_or_aiming_started(used_card: Node) -> void:
	if used_card == self: return
	disabled = true

func _on_card_drag_or_aim_ended(_card: Node) -> void:
	disabled = false
	playable = stats.can_play_card(card) if stats else false

func _on_card_drawn() -> void:
	playable = stats.can_play_card(card) if stats else false

func _set_playable(value: bool) -> void:
	playable = value
	if not playable:
		card_render.card_visuals.cost.add_theme_color_override("font_color", Color.RED)
		card_render.card_visuals.icon.modulate = Color(1, 1, 1, 0.5)
	else:
		card_render.card_visuals.cost.remove_theme_color_override("font_color")
		card_render.card_visuals.icon.modulate = Color(1, 1, 1, 1)

func request_tooltip() -> void:
	var enemy_modifiers := get_active_enemy_modifiers()
	var updated_tooltip := card.get_updated_tooltip(modifiers, enemy_modifiers)
	Events.card_tooltip_requested.emit(card.icon, updated_tooltip)

func select() -> void:
	selected = true

func deselect() -> void:
	selected = false

func get_active_enemy_modifiers() -> ModifierHandler:
	if targets.is_empty() or targets.size() > 1 or not targets[0] is Enemy:
		return null
	return targets[0].modifier_handler

func _on_drop_point_detector_area_entered(area):
	if not targets.has(area):
		targets.append(area)

func _on_drop_point_detector_area_exited(area):
	targets.erase(area)
