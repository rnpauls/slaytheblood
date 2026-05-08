class_name EquipmentUI
extends Control

@export var equipment: Equipment : set = set_equipment
@export var shader_material: ShaderMaterial
@onready var icon: TextureRect = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var block_label: Label = %BlockLabel
@onready var glow_panel: Panel = %GlowPanel

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
	# Tint label to flag damaged state (current < max).
	if equipment.current_block < equipment.max_block:
		block_label.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
	else:
		block_label.remove_theme_color_override("font_color")

func set_glow(enabled: bool) -> void:
	if not is_node_ready():
		await ready
	glow_panel.visible = enabled and equipment != null


func flash() -> void:
	if animation_player and animation_player.has_animation("flash"):
		animation_player.play("flash")
