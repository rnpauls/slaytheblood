class_name WeaponHandler
extends Control

@export var activable: bool = false
@export var targeting: bool = false
@export var owner_of_weapon: Node #: set = set_owner_of_weapon
@onready var weapon_ui: WeaponUI = $WeaponButton/WeaponUI
@onready var weapon_button: Button = %WeaponButton
var targets: Array[Node]
var weapon: Weapon

func _ready() -> void:
	Events.player_initial_hand_drawn.connect(enable_weapon)
	Events.enemy_phase_ended.connect(enable_weapon)

func _input(event: InputEvent) -> void:
	if targeting:
		if event.is_action_pressed("right_mouse") or event.is_action_pressed("ui_cancel"):
			end_targeting()
		if event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
			if not targets.is_empty():
			#get_viewport().set_input_as_handled()
				self.accept_event()
				attempt_to_attack()
				end_targeting()

func set_weapon(new_weapon: Weapon) -> void:
	if not is_node_ready():
		await ready
	if new_weapon:
		weapon_ui.weapon = new_weapon
		weapon = weapon_ui.weapon
		weapon.owner = owner_of_weapon
		weapon.weapon_used_up.connect(_on_weapon_used_up)
	else:
		hide()


func flash() -> void:
	weapon_ui.animation_player.play("flash")
	
func _on_weapon_used_up() -> void:
	disable_weapon()

func disable_weapon() -> void:
	if not weapon: return 
	activable = false
	weapon_ui.set_grey_out(true)
	weapon_button.disabled = true

func enable_weapon() -> void:
	if not weapon: return
	activable = true
	weapon_ui.set_grey_out(false)
	weapon_button.disabled = false

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
		weapon.activate_weapon(targets, owner_of_weapon.modifier_handler)
			#Events.tooltip_hide_requested.emit()
		owner_of_weapon.attack_completed.emit()
		Hook.after_attack_completed(owner_of_weapon, {})
		if owner_of_weapon is Player:
			Events.player_attack_completed.emit() #Needed for relics e.g. ira

func _on_weapon_button_pressed() -> void:
	if can_activate_weapon():
		begin_targeting()

func _on_mouse_entered() -> void:
	weapon_ui.request_tooltip()

func _on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
