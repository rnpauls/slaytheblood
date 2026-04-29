## Base card display + data class.
## Does NOT connect to any Events, does NOT have a state machine.
## PlayerCardUI and EnemyCardUI extend this.
class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_stylebox.tres")
const DRAG_STYLEBOX := preload("res://scenes/card_ui/card_dragging_stylebox.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_stylebox.tres")
const SELECTED_STYLEBOX := preload("res://scenes/card_ui/card_selected_stylebox.tres")

@export var modifier_handler: ModifierHandler
@export var card: Card : set = _set_card
## Accepts both CharacterStats and EnemyStats since both extend Stats.
@export var char_stats: Stats : set = _set_char_stats
@export var hover_scale := 1.0
@export var tween_duration := 0.18

@onready var card_render: CardRenderContainer = $CardRenderContainer

var original_parent: Node
var original_index: int = -1
var original_global_pos: Vector2
var is_hovered := false
var tween: Tween
var targets: Array[Node] = []

signal card_hovered(CardUI)
signal card_unhovered(CardUI)


func animate_to_position(new_position: Vector2, duration: float) -> void:
	_kill_tween()
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)

func animate_to_local_position_and_rotation_and_scale(new_position: Vector2, new_rotation: float, new_scale: float, duration: float) -> void:
	_kill_tween()
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", new_position, duration)
	tween.parallel().tween_property(self, "rotation_degrees", new_rotation, duration)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * new_scale, duration)

func return_to_hand() -> void:
	_return_to_original_parent()

func play() -> void:
	if not card:
		return
	card.play(self, targets, char_stats, modifier_handler)
	queue_free()

func discard() -> void:
	if not card:
		return
	card.discard_card()
	queue_free()

func pitch() -> void:
	if not card:
		return
	card.pitch_card(char_stats)
	queue_free()

func sink() -> void:
	if not card:
		return
	card.sink_card(char_stats)
	queue_free()

func block() -> void:
	if not card:
		return
	card.block_card([card.owner], modifier_handler)
	queue_free()

func get_active_enemy_modifiers() -> ModifierHandler:
	if targets.is_empty() or targets.size() > 1 or targets[0] is not Enemy:
		return null
	return targets[0].modifier_handler

func mouse_is_over() -> bool:
	var rect := Rect2(Vector2.ZERO, self.size)
	return rect.has_point(get_local_mouse_position())

func request_tooltip() -> void:
	var enemy_modifiers := get_active_enemy_modifiers()
	var updated_tooltip := card.get_updated_tooltip(modifier_handler, enemy_modifiers)
	Events.card_tooltip_requested.emit(card.icon, updated_tooltip)

func select() -> void:
	pass

func deselect() -> void:
	pass

func _return_to_original_parent() -> void:
	if not is_inside_tree(): return
	reparent_requested.emit(self)
	z_index = 0
	scale = Vector2.ONE * 0.7

func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	card_render.card = card

func _set_char_stats(value: Stats) -> void:
	char_stats = value
	if char_stats and not char_stats.stats_changed.is_connected(_on_char_stats_changed):
		char_stats.stats_changed.connect(_on_char_stats_changed)

func _on_char_stats_changed() -> void:
	pass

func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)

func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)

func _kill_tween() -> void:
	if tween and tween.is_running():
		tween.kill()
