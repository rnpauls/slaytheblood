class_name WeaponUI
extends Control

@export var weapon: Weapon
@export var activable: bool = false
@export var targeting: bool = false
@export var shader_material: ShaderMaterial
var targets: Array[Node]

@onready var icon: TextureButton = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://art/shaders/greyscale.gdshader")
	
	Events.player_initial_hand_drawn.connect(enable_weapon)
	Events.enemy_phase_ended.connect(enable_weapon)
	#weapon = preload("res://weapons/explosive_barrel.tres")
	#await get_tree().create_timer(1).timeout
	#flash()
	weapon = null

func _input(event: InputEvent) -> void:
	if (event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse") ) and targeting:
		if not targets.is_empty():
		#get_viewport().set_input_as_handled()
			self.accept_event()
			attempt_to_attack()
			end_targeting()

func set_weapon(new_weapon: Weapon) -> void:
	if not is_node_ready():
		await ready
	weapon = new_weapon
	if not weapon:
		icon.texture_normal = null
		return
	#print("setting up weapon %s" % new_weapon.id)
	icon.texture_normal = weapon.icon
	icon.material = shader_material
	weapon.weapon_used_up.connect(_on_weapon_used_up)

func flash() -> void:
	animation_player.play("flash")

#func _on_gui_input(event: InputEvent) -> void:
	#if event.is_action_pressed("left_mouse"):
		#Events.weapon_tooltip_requested.emit(weapon)

func _on_weapon_used_up() -> void:
	disable_weapon()

func disable_weapon() -> void:
	if not weapon: return 
	activable = false
	set_grey_out(true)

func enable_weapon() -> void:
	if not weapon: return
	activable = true
	set_grey_out(false)

func reset() -> void:
	if not weapon: return
	weapon.reset()

func can_activate_weapon() -> bool:
	if not weapon: return false
	var player: Player = get_tree().get_first_node_in_group("player")
	var mana:= player.stats.mana
	var ap := player.stats.action_points
	if activable and (mana >= weapon.cost) and (ap > 0):
		return true
	else:
		return false

func set_grey_out(enabled: bool):
	if not weapon: return
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
