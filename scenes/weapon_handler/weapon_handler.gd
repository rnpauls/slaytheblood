class_name WeaponHandler
extends Control

const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_TWEEN_TIME := 0.1

## When false: skip combat-event listeners, swallow combat input, and the click
## handler does nothing — used by the inventory view to display equipped weapons
## without wiring any combat behavior. The button still emits `pressed` so the
## containing UI can connect its own handler (e.g. unequip).
@export var interactive: bool = true
@export var activable: bool = false
@export var targeting: bool = false
@export var owner_of_weapon: Node #: set = set_owner_of_weapon
@onready var weapon_ui: WeaponUI = $WeaponButton/WeaponUI
@onready var weapon_button: Button = %WeaponButton
@onready var hover_glow_panel: Panel = %HoverGlowPanel
var targets: Array[Node]
var weapon: Weapon
var _hover_tween: Tween

func _ready() -> void:
	if not interactive:
		return
	Events.player_initial_hand_drawn.connect(enable_weapon)
	Events.enemy_phase_ended.connect(enable_weapon)

func _input(event: InputEvent) -> void:
	if not interactive:
		return
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
	# Detach the previously-wielded weapon (if any) before swapping. Covers both
	# unequip (new_weapon == null) and re-equip with a different weapon.
	var previous := weapon
	if previous and previous != new_weapon:
		var prev_combatant := owner_of_weapon as Combatant
		if prev_combatant:
			previous.detach_from_combatant(prev_combatant)
	if new_weapon:
		weapon_ui.weapon = new_weapon
		weapon = weapon_ui.weapon
		if interactive:
			weapon.owner = owner_of_weapon
			weapon.weapon_used_up.connect(_on_weapon_used_up)
			_connect_stats_for_glow()
			_update_glow()
		var combatant := owner_of_weapon as Combatant
		if combatant:
			weapon.attach_to_combatant(combatant)
	else:
		weapon = null
		hide()


# Connects to the wielder's stats_changed signal so the glow reflects mana /
# AP in real time. Safe to call repeatedly — duplicate connections are skipped.
func _connect_stats_for_glow() -> void:
	var combatant := owner_of_weapon as Combatant
	if combatant and combatant.stats:
		if not combatant.stats.stats_changed.is_connected(_update_glow):
			combatant.stats.stats_changed.connect(_update_glow)


func _update_glow() -> void:
	if weapon_ui:
		weapon_ui.set_glow(can_activate_weapon())


func flash() -> void:
	weapon_ui.animation_player.play("flash")
	
func _on_weapon_used_up() -> void:
	if weapon.is_single_use:
		if owner_of_weapon is Player:
			owner_of_weapon.stats.inventory.remove_equipment(weapon)
		var combatant := owner_of_weapon as Combatant
		if combatant:
			weapon.detach_from_combatant(combatant)
		weapon.queue_free()
		hide()

	disable_weapon()

func disable_weapon() -> void:
	if not weapon: return
	activable = false
	weapon_ui.set_grey_out(true)
	weapon_button.disabled = true
	_update_glow()

func enable_weapon() -> void:
	if not weapon: return
	activable = true
	weapon_ui.set_grey_out(false)
	weapon_button.disabled = false
	_update_glow()

func reset() -> void:
	if not weapon: return
	weapon.reset()

func can_activate_weapon() -> bool:
	if not weapon: return false
	var combatant := owner_of_weapon as Combatant
	if not combatant or not combatant.stats:
		return false
	var mana := combatant.stats.mana
	var ap := combatant.stats.action_points
	return activable and (mana >= weapon.cost) and (ap > 0)

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
		if owner_of_weapon is Player:
			Events.player_attack_completed.emit() #Needed for relics e.g. ira

func _on_weapon_button_pressed() -> void:
	if not interactive:
		return
	if can_activate_weapon():
		begin_targeting()

func _on_mouse_entered() -> void:
	if not weapon:
		return
	_set_hovered(true)
	var anchor_rect := Rect2(weapon_button.global_position, weapon_button.size)
	Events.inventory_preview_show_requested.emit(weapon, null, anchor_rect)

func _on_mouse_exited() -> void:
	_set_hovered(false)
	Events.inventory_preview_hide_requested.emit()


func _set_hovered(value: bool) -> void:
	hover_glow_panel.visible = value
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(weapon_button, "scale", HOVER_SCALE if value else Vector2.ONE, HOVER_TWEEN_TIME)
