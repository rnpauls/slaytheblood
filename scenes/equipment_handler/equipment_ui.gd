class_name EquipmentUI
extends Control

const WARNING_BADGE_PATH := "res://art/equipment_badges/warning.png"
const INFINITY_BADGE_PATH := "res://art/equipment_badges/infinity.png"

@export var equipment: Equipment : set = set_equipment
@export var shader_material: ShaderMaterial
@onready var icon: TextureRect = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var block_label: Label = %BlockLabel
@onready var glow_panel: Panel = %GlowPanel
@onready var status_badge: TextureRect = $StatusBadge

func _ready() -> void:
	shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://art/shaders/greyscale.gdshader")
	equipment = null

func set_equipment(new_equipment: Equipment) -> void:
	if not is_node_ready():
		await ready
	if not new_equipment:
		icon.texture = null
		block_label.text = ""
		return
	icon.texture = new_equipment.icon
	icon.material = shader_material
	equipment = new_equipment
	update_block_label()

func set_grey_out(enabled: bool) -> void:
	if not equipment:
		return
	var mat := icon.material
	if mat:
		if enabled:
			mat.set_shader_parameter("strength", 1.0)
			icon.modulate = Color(0.3, 0.3, 0.3)
		else:
			mat.set_shader_parameter("strength", 0.0)
			icon.modulate = Color(1, 1, 1)

func update_block_label() -> void:
	if not equipment or not block_label:
		return
	block_label.text = str(equipment.current_block)
	var fragile := equipment.single_use or equipment.current_block == 1
	var immortal := equipment.regenerates_each_battle and equipment.unbreakable
	# Red tint flags "breaks on next defend" — skipped for immortal items.
	if fragile and not immortal:
		block_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		block_label.remove_theme_color_override("font_color")
	_update_status_badge(immortal, fragile)


func _update_status_badge(immortal: bool, fragile: bool) -> void:
	if not status_badge:
		return
	if immortal:
		status_badge.texture = _load_badge(INFINITY_BADGE_PATH)
		status_badge.visible = status_badge.texture != null
	elif fragile:
		status_badge.texture = _load_badge(WARNING_BADGE_PATH)
		status_badge.visible = status_badge.texture != null
	else:
		status_badge.visible = false


func _load_badge(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func set_glow(enabled: bool) -> void:
	if not is_node_ready():
		await ready
	glow_panel.visible = enabled and equipment != null


func flash() -> void:
	if animation_player and animation_player.has_animation("flash"):
		animation_player.play("flash")
