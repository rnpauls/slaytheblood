class_name WeaponUI
extends Control

@export var weapon: Weapon : set = set_weapon
@export var shader_material: ShaderMaterial
## Wired by WeaponHandler from owner_of_weapon.modifier_handler. When null
## (inventory screen, etc.) update_labels renders raw weapon stats.
var modifier_handler: ModifierHandler = null
@onready var icon: TextureRect = $Icon
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var atk_label: Label = %AtkLabel
@onready var cost_label: Label = %CostLabel
@onready var glow_panel: Panel = %GlowPanel
@onready var go_again_icon: TextureRect = $GoAgainIcon

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
		go_again_icon.hide()
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
		icon.modulate =Color(0.3,0.3,0.3)
	else:
		mat.set_shader_parameter("strength", 0.0)
		icon.modulate =Color(1,1,1)

func set_glow(enabled: bool) -> void:
	if not is_node_ready():
		await ready
	glow_panel.visible = enabled and weapon != null

func update_labels() -> void:
	var base_atk := weapon.attack
	var display_atk := weapon.get_display_attack()
	var mod_atk := display_atk
	if modifier_handler:
		mod_atk = modifier_handler.get_modified_value(display_atk, Modifier.Type.DMG_DEALT)
	_apply_value_tint(atk_label, base_atk, mod_atk)

	var base_cost := weapon.cost
	var mod_cost := base_cost
	if modifier_handler:
		mod_cost = modifier_handler.get_modified_value(base_cost, Modifier.Type.CARD_COST)
	_apply_value_tint(cost_label, base_cost, mod_cost)

	refresh_go_again()


func _apply_value_tint(label: Label, base: int, modified: int) -> void:
	label.text = str(modified)
	if modified > base:
		label.add_theme_color_override("font_color", Palette.GOLD_HIGHLIGHT)
	elif modified < base:
		label.add_theme_color_override("font_color", Palette.BLOOD_CRIMSON)
	else:
		label.remove_theme_color_override("font_color")

func refresh_go_again() -> void:
	if not is_node_ready():
		await ready
	if not weapon:
		go_again_icon.hide()
		return
	go_again_icon.visible = weapon.would_go_again()

#func request_tooltip() -> void:
	#var tt_text: = weapon.get_tooltip()
	#print("Request weapon tooltip %s" % tt_text)
	#
