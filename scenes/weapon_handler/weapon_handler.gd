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
		# Wire the wielder's modifier_handler BEFORE assigning the weapon, so
		# WeaponUI.set_weapon's initial update_labels() picks up modifier tints
		# instead of writing raw stats and waiting for the next refresh.
		var pre_handler: ModifierHandler = null
		if owner_of_weapon and owner_of_weapon.get("modifier_handler"):
			pre_handler = owner_of_weapon.modifier_handler
		weapon_ui.modifier_handler = pre_handler
		weapon_ui.weapon = new_weapon
		weapon = weapon_ui.weapon
		if interactive:
			weapon.owner = owner_of_weapon
			weapon.weapon_used_up.connect(_on_weapon_used_up)
			_connect_stats_for_glow()
			_connect_modifiers_for_labels()
			_update_glow()
			# Owner was just assigned, so dynamic weapons can now read live
			# status. Re-evaluate the go_again badge.
			weapon_ui.refresh_go_again()
		var combatant := owner_of_weapon as Combatant
		if combatant:
			weapon.attach_to_combatant(combatant)
	else:
		weapon = null
		hide()


# Connects to the wielder's stats_changed signal so the glow reflects mana /
# AP in real time, and to statuses_changed so the go-again badge re-evaluates
# whenever the wielder gains or loses a status (e.g. enraged / flow).
# Safe to call repeatedly — duplicate connections are skipped.
func _connect_stats_for_glow() -> void:
	var combatant := owner_of_weapon as Combatant
	if combatant and combatant.stats:
		if not combatant.stats.stats_changed.is_connected(_update_glow):
			combatant.stats.stats_changed.connect(_update_glow)
	if combatant and combatant.status_handler:
		if not combatant.status_handler.statuses_changed.is_connected(_on_statuses_changed):
			combatant.status_handler.statuses_changed.connect(_on_statuses_changed)


# Connects to the wielder's ModifierHandler so the weapon's atk/cost labels
# re-tint when buffs/debuffs come, go, or change stack counts mid-combat.
# Safe to call repeatedly — duplicate connections are skipped.
func _connect_modifiers_for_labels() -> void:
	if owner_of_weapon and owner_of_weapon.get("modifier_handler"):
		var mh: ModifierHandler = owner_of_weapon.modifier_handler
		if mh and not mh.modifiers_changed.is_connected(_on_modifiers_changed):
			mh.modifiers_changed.connect(_on_modifiers_changed)


func _on_modifiers_changed() -> void:
	if weapon_ui and weapon:
		weapon_ui.update_labels()


func _update_glow() -> void:
	if weapon_ui:
		weapon_ui.set_glow(can_activate_weapon())


func _on_statuses_changed() -> void:
	if weapon_ui:
		weapon_ui.refresh_go_again()


func flash() -> void:
	weapon_ui.animation_player.play("flash")
	
func _on_weapon_used_up() -> void:
	if weapon.is_single_use:
		_destroy_weapon()
	disable_weapon()


func _destroy_weapon() -> void:
	var destroyed := weapon
	if owner_of_weapon is Player:
		var stats := (owner_of_weapon as Player).stats
		if stats:
			if stats.inventory:
				stats.inventory.remove_weapon(destroyed)
			if stats.hand_left == destroyed:
				stats.hand_left = null
			elif stats.hand_right == destroyed:
				stats.hand_right = null
	set_weapon(null)

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
	# Underlying Area2D mouse_exited doesn't fire when this Button captures the
	# mouse, so clear any stale tooltip explicitly.
	Events.tooltip_hide_requested.emit()
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
