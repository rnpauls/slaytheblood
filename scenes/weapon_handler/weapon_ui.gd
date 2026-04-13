class_name WeaponUI
extends Control

@export var weapon: Weapon : set = set_weapon
@export var shader_material: ShaderMaterial
@onready var icon: TextureRect = $Icon
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var atk_label: Label = %AtkLabel
@onready var cost_label: Label = %CostLabel

func _ready() -> void:
	shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://art/shaders/greyscale.gdshader")
	#weapon = preload("res://weapons/explosive_barrel.tres")
	#await get_tree().create_timer(1).timeout
	#flash()
	weapon = null

func set_weapon(new_weapon: Weapon) -> void:
	if not is_node_ready():
		await ready
	if not new_weapon:
		icon.texture = null
		return
	#print("setting up weapon %s" % new_weapon.id)
	icon.texture = new_weapon.icon
	icon.material = shader_material
	weapon = new_weapon
	update_labels()

func set_grey_out(enabled: bool):
	if not weapon: return
	var mat:= icon.material
	if enabled:
		mat.set_shader_parameter("strength", 1.0)
		icon.modulate =Color(0.6,0.6,0.6)
	else:
		mat.set_shader_parameter("strength", 0.0)
		icon.modulate =Color(1,1,1)

func update_labels() -> void:
	atk_label.text = str(weapon.attack)
	cost_label.text = str(weapon.cost)

#func request_tooltip() -> void:
	#var tt_text: = weapon.get_tooltip()
	#print("Request weapon tooltip %s" % tt_text)
	#
