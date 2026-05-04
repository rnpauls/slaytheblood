class_name RelicUI
extends Control

@export var relic: Relic : set = set_relic

@onready var icon: TextureRect = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

#func _ready() -> void:
	#relic = preload("res://relics/explosive_barrel.tres")
	#await get_tree().create_timer(1).timeout
	#flash()

func set_relic(new_relic: Relic) -> void:
	if not is_node_ready():
		await ready
	
	relic = new_relic
	icon.texture = relic.icon

func flash() -> void:
	animation_player.play("flash")

func _on_mouse_entered() -> void:
	if not relic:
		return
	var body := relic.get_tooltip()
	var entries: Array[TooltipData] = [
		TooltipData.make(relic.icon, relic.relic_name, body),
	]
	entries.append_array(KeywordRegistry.build_tooltip_chain(body))
	Events.tooltip_show_requested.emit(entries, Rect2(global_position, size))


func _on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
