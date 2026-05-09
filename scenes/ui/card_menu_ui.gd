class_name CardMenuUI
extends CenterContainer

signal tooltip_requested(card: Card)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_stylebox.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_stylebox.tres")

@export var card: Card : set = set_card
@export var hover_scale := 1.1

@onready var visuals: CardVisuals = $Visuals


func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)


func _on_visuals_mouse_entered() -> void:
	visuals.panel.set("theme_override_styles/panel", HOVER_STYLEBOX)
	visuals.pivot_offset = visuals.size / 2.0
	visuals.scale = Vector2.ONE * hover_scale
	z_index = 20
	if not card:
		return
	var entries: Array[TooltipData] = KeywordRegistry.build_tooltip_chain(card.get_default_tooltip())
	if not entries.is_empty():
		Events.tooltip_show_requested.emit(entries, Rect2(visuals.global_position, visuals.size))


func _on_visuals_mouse_exited() -> void:
	visuals.panel.set("theme_override_styles/panel", BASE_STYLEBOX)
	visuals.scale = Vector2.ONE
	z_index = 0
	Events.tooltip_hide_requested.emit()


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	visuals.card = card
