@tool
class_name RelicUI
extends Control

@export var relic: Relic : set = set_relic
@export_range(0.1, 4.0, 0.05) var base_scale: float = 1.0 : set = set_base_scale

@onready var icon: TextureRect = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_apply_base_scale()


func set_relic(new_relic: Relic) -> void:
	if not is_node_ready():
		await ready

	relic = new_relic
	if relic and icon:
		icon.texture = relic.icon


func set_base_scale(value: float) -> void:
	base_scale = value
	if is_node_ready():
		_apply_base_scale()
		update_minimum_size()


func _apply_base_scale() -> void:
	pivot_offset = custom_minimum_size / 2.0
	scale = Vector2.ONE * base_scale


func _get_minimum_size() -> Vector2:
	return custom_minimum_size * base_scale


func flash() -> void:
	if Engine.is_editor_hint():
		return
	animation_player.play("flash")

func _on_mouse_entered() -> void:
	if Engine.is_editor_hint():
		return
	if not relic:
		return
	var body := relic.get_tooltip()
	var entries: Array[TooltipData] = [
		TooltipData.make(relic.icon, relic.relic_name, body),
	]
	entries.append_array(KeywordRegistry.build_tooltip_chain(body))
	Events.tooltip_show_requested.emit(entries, Rect2(global_position, size))


func _on_mouse_exited() -> void:
	if Engine.is_editor_hint():
		return
	Events.tooltip_hide_requested.emit()
