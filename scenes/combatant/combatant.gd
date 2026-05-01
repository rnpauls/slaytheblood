## Participates in the Hook system: registers on _ready, unregisters on _exit_tree.
## Enemy and Player subclasses can override hook methods directly to implement
## innate abilities (e.g. an enemy that has a passive damage modifier).
class_name Combatant
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/themes/white_sprite_material.tres")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var status_handler: StatusHandler = $StatusHandler

@export var stats: Stats : set = set_stats
var active_on_hits: Array[OnHit]

signal attack_completed

func _ready() -> void:
	Hook.on_model_entered(self)

func _exit_tree() -> void:
	Hook.on_model_exited(self)

func set_stats(value: Stats) -> void:
	stats = _init_stats(value)
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	_on_stats_set()

## Override to transform the incoming stats value before it is assigned.
## e.g. Enemy calls value.create_instance() here.
func _init_stats(value: Stats) -> Stats:
	return value

## Override to react after stats is assigned and the signal is connected.
func _on_stats_set() -> void:
	pass

func update_stats() -> void:
	stats_ui.update_stats(stats)

func take_damage(damage: int) -> int:
	if stats.health <= 0:
		return 0

	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var damage_taken := stats.take_damage(damage)

	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_interval(0.17)
	tween.finished.connect(func():
		sprite_2d.material = null
		if stats.health <= 0:
			_on_death()
	)
	return damage_taken

## Override in subclasses to handle death (emit event, queue_free, etc.)
func _on_death() -> void:
	pass
