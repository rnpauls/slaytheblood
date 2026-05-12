@tool
class_name CardMenuUI
extends CenterContainer

signal tooltip_requested(card: Card)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_stylebox.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_stylebox.tres")

@export var card: Card : set = set_card
@export_range(0.1, 2.0, 0.05) var base_scale: float = 0.8 : set = set_base_scale
@export var hover_scale := 1.1

@onready var visuals: CardVisuals = $Visuals
@onready var glow_panel: Panel = $Visuals/GlowPanel


func _ready() -> void:
	# CenterContainer.fit_child_in_rect resets visuals.scale to (1, 1) every
	# sort, so re-apply on each sort to keep base_scale in effect.
	sort_children.connect(_apply_base_scale)
	_apply_base_scale()


func set_base_scale(value: float) -> void:
	base_scale = value
	if is_node_ready():
		_apply_base_scale()
		update_minimum_size()


func _apply_base_scale() -> void:
	if visuals == null:
		return
	visuals.pivot_offset = visuals.custom_minimum_size / 2.0
	visuals.scale = Vector2.ONE * base_scale
	update_minimum_size()


func _get_minimum_size() -> Vector2:
	if visuals == null:
		return Vector2.ZERO
	return visuals.custom_minimum_size * base_scale


func _on_visuals_gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)


func _on_visuals_mouse_entered() -> void:
	if Engine.is_editor_hint():
		return
	SFXRegistry.play(&"HOVER_UI")
	visuals.panel.set("theme_override_styles/panel", HOVER_STYLEBOX)
	visuals.pivot_offset = visuals.size / 2.0
	visuals.scale = Vector2.ONE * base_scale * hover_scale
	z_index = 20
	glow_panel.visible = true
	if not card:
		return
	var entries: Array[TooltipData] = KeywordRegistry.build_tooltip_chain(card.get_default_tooltip())
	if not entries.is_empty():
		Events.tooltip_show_requested.emit(entries, Rect2(visuals.global_position, visuals.size))


func _on_visuals_mouse_exited() -> void:
	if Engine.is_editor_hint():
		return
	visuals.panel.set("theme_override_styles/panel", BASE_STYLEBOX)
	visuals.scale = Vector2.ONE * base_scale
	z_index = 0
	glow_panel.visible = false
	Events.tooltip_hide_requested.emit()


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	visuals.card = card
