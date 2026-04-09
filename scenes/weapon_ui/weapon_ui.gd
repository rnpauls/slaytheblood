class_name WeaponUI
extends Control

@export var weapon: Weapon : set = set_weapon
@export var activable: bool = false
@export var targeting: bool = false
var targets: Array

@onready var icon: TextureButton = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	var material = ShaderMaterial.new()
	material.shader = preload("res://art/shaders/greyscale.gdshader")
	icon.material = material
	#weapon = preload("res://weapons/explosive_barrel.tres")
	#await get_tree().create_timer(1).timeout
	#flash()

func on_input(event: InputEvent) -> void:
	if event.is_action_released("left_mouse") and targeting:
		if not targets.is_empty():
		#get_viewport().set_input_as_handled()
			self.accept_event()
			attempt_to_attack()
			end_targeting()

func set_weapon(new_weapon: Weapon) -> void:
	if not is_node_ready():
		await ready
	
	weapon = new_weapon
	icon.texture = weapon.icon
	weapon.weapon_used_up.connect(_on_weapon_used_up)

func flash() -> void:
	animation_player.play("flash")

#func _on_gui_input(event: InputEvent) -> void:
	#if event.is_action_pressed("left_mouse"):
		#Events.weapon_tooltip_requested.emit(weapon)

func _on_weapon_used_up() -> void:
	disable_weapon()

func disable_weapon() -> void:
	activable = false
	set_grey_out(true)

func enable_weapon() -> void:
	activable = true
	set_grey_out(false)

func reset() -> void:
	weapon.reset()

func can_activate_weapon() -> bool:
	var player: Player = get_tree().get_first_node_in_group("player")
	var mana:= player.stats.mana
	var ap := player.stats.action_points
	if activable and (mana >= weapon.cost) and (ap > 0):
		return true
	else:
		return false

func set_grey_out(enabled: bool):
	var mat:= icon.material
	if enabled:
		mat.set_shader_parameter("strength", 1.0)
		icon.modulate =Color(0.6,0.6,0.6)
	else:
		mat.set_shader_parameter("strength", 0.0)
		icon.modulate =Color(1,1,1)


func _on_icon_pressed() -> void:
	if can_activate_weapon():
		begin_targeting()

func begin_targeting() -> void:
	targeting = true
	Events.card_aim_started.emit(self)

func end_targeting() -> void:
	targeting = false
	targets = []
	Events.card_aim_ended.emit(self)

func attempt_to_attack() -> void:
	if not targets.is_empty():
		#print(card_ui.targets[0].get_class())
		#if targets[0] is Enemy:
		weapon.activate_weapon(targets)
			#Events.tooltip_hide_requested.emit()
