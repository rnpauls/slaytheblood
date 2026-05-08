class_name EquipmentHandler
extends Control

## Per-slot equipment handler. Listens for incoming attacks (enemy_attack_declared)
## and lets the player click this slot to consume its block value into player.stats.block.
## After being clicked once during an attack, it greys out until the next incoming attack.

signal equipment_destroyed(equipment: Equipment)

const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_TWEEN_TIME := 0.1

## When false: skip combat-event listeners and the click handler does nothing.
## Used by the inventory view to display equipped items without resetting their
## current_block (which would clobber a partially-used piece mid-battle) and
## without wiring any combat behavior. The button still emits `pressed`.
@export var interactive: bool = true
@export var owner_of_equipment: Node
@onready var equipment_ui: EquipmentUI = $EquipmentButton/EquipmentUI
@onready var equipment_button: Button = %EquipmentButton
@onready var hover_glow_panel: Panel = %HoverGlowPanel

var equipment: Equipment
var is_blocking: bool = false
var is_action_phase: bool = false
var _hover_tween: Tween

func _ready() -> void:
	if not interactive:
		return
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.player_blocks_declared.connect(_on_player_blocks_declared)
	Events.player_action_phase_started.connect(_on_player_action_phase_started)
	Events.player_end_phase_started.connect(_on_player_end_phase_started)


func set_equipment(new_equipment: Equipment) -> void:
	if not is_node_ready():
		await ready
	# Deactivate the equipment we're replacing so it can disconnect signal hooks
	# (Tabi Boots etc. listen on the global Events bus and would otherwise
	# linger as zombie listeners after the swap).
	if equipment and equipment != new_equipment and interactive:
		equipment.deactivate_equipment(owner_of_equipment)
	if new_equipment:
		equipment_ui.equipment = new_equipment
		equipment = equipment_ui.equipment
		if interactive:
			equipment.owner = owner_of_equipment
			equipment.initialize_equipment(owner_of_equipment)
			_connect_stats_for_glow()
		show()
		_refresh_button_state()
	else:
		equipment = null
		equipment_ui.equipment = null
		hide()


# Mirrors WeaponHandler._connect_stats_for_glow so the active-ability glow
# refreshes whenever AP changes mid-turn.
func _connect_stats_for_glow() -> void:
	var player := owner_of_equipment as Player
	if player and player.stats:
		if not player.stats.stats_changed.is_connected(_refresh_button_state):
			player.stats.stats_changed.connect(_refresh_button_state)


func flash() -> void:
	if equipment_ui.has_method("flash"):
		equipment_ui.flash()


## Called per incoming attack. Re-enables click on the slot.
func _on_enemy_attack_declared() -> void:
	is_blocking = true
	if equipment:
		equipment.reset_for_attack()
	_refresh_button_state()


## Called when defending phase ends. Disables click.
func _on_player_blocks_declared() -> void:
	is_blocking = false
	_refresh_button_state()


func _on_player_action_phase_started() -> void:
	is_action_phase = true
	_refresh_button_state()


func _on_player_end_phase_started() -> void:
	is_action_phase = false
	if equipment:
		equipment.reset_active_ability()
	_refresh_button_state()


## End-of-battle restore for REUSABLE equipment.
func restore_for_battle() -> void:
	if not equipment:
		return
	equipment.restore_for_battle()
	_refresh_button_state()


func can_block() -> bool:
	return equipment != null \
		and is_blocking \
		and not equipment.used_this_attack \
		and equipment.current_block > 0


func can_use_active_ability() -> bool:
	return equipment != null \
		and is_action_phase \
		and equipment.can_use_active_ability(owner_of_equipment)


func _refresh_button_state() -> void:
	if not equipment:
		equipment_button.disabled = true
		equipment_ui.set_grey_out(true)
		equipment_ui.set_glow(false)
		return
	if not interactive:
		# Viewer mode: show as lit; the containing UI manages click-disabling
		# (e.g. when combat is in progress and equipment swaps are forbidden).
		equipment_button.disabled = false
		equipment_ui.set_grey_out(false)
		equipment_ui.set_glow(false)
		equipment_ui.update_block_label()
		return
	var ability_ready := can_use_active_ability()
	var available := can_block() or ability_ready
	equipment_button.disabled = not available
	equipment_ui.set_grey_out(not available)
	equipment_ui.set_glow(ability_ready)
	equipment_ui.update_block_label()


func attempt_to_use_ability() -> void:
	if not can_use_active_ability():
		return
	equipment.use_active_ability(owner_of_equipment)
	flash()
	_refresh_button_state()


func attempt_to_block() -> void:
	if not can_block():
		return
	# Fire optional triggered ability before adding block, so an "on-defend"
	# triggered effect resolves visually before the block number jumps.
	if equipment.trigger_relic:
		# trigger_relic.activate_relic expects a RelicUI but most relics only
		# need the owner's tree; we pass the equipment_ui as a stand-in. If a
		# specific trigger relic needs richer context, extend that relic to
		# accept Variant and pull from owner_of_equipment.
		print_debug("Equipment trigger relics not implemented")
		#equipment.trigger_relic.activate_relic(equipment_ui)

	var block_amount := equipment.consume_block_for_attack()

	var player := owner_of_equipment as Player
	if player:
		var block_effect := BlockEffect.new()
		block_effect.amount = block_amount
		block_effect.sound = equipment.sound
		block_effect.execute([player])

	# Fire the on-block hook (Smoke Capsule draws a card, Berserker Helm gains
	# Muscle, Spiked Pauldrons applies Thorns, etc.). Runs whether or not the
	# equipment was destroyed by this use, so dying-use effects still trigger.
	equipment.on_block_consumed(owner_of_equipment)

	flash()

	if equipment.is_destroyed():
		_destroy_equipment()
	else:
		_refresh_button_state()


func _destroy_equipment() -> void:
	var destroyed := equipment
	# Fire the on-destroyed hook before we tear it down so Heavy Greaves etc.
	# can grant their last-rites effect.
	destroyed.on_destroyed(owner_of_equipment)
	# Disconnect any global-signal hooks the equipment registered.
	destroyed.deactivate_equipment(owner_of_equipment)
	equipment_destroyed.emit(destroyed)
	# ONE_SHOT: remove from inventory entirely so it's gone after battle.
	# REUSABLE: keep in inventory; restore_for_battle will refresh it.
	if destroyed.persistence == Equipment.Persistence.ONE_SHOT:
		var player := owner_of_equipment as Player
		if player and player.stats and player.stats.inventory:
			player.stats.inventory.remove_equipment(destroyed)
		# Also clear the equipped slot reference on the character.
		_clear_equipped_slot_on_character(destroyed)
		set_equipment(null)
	else:
		# REUSABLE but currently broken — keep it in the slot, just disabled.
		# It'll restore at end of battle.
		_refresh_button_state()


func _clear_equipped_slot_on_character(eq: Equipment) -> void:
	var player := owner_of_equipment as Player
	if not player or not player.stats:
		return
	var stats := player.stats
	match eq.slot:
		Equipment.Slot.HEAD:
			if stats.equipment_head == eq: stats.equipment_head = null
		Equipment.Slot.CHEST:
			if stats.equipment_chest == eq: stats.equipment_chest = null
		Equipment.Slot.ARMS:
			if stats.equipment_arms == eq: stats.equipment_arms = null
		Equipment.Slot.LEGS:
			if stats.equipment_legs == eq: stats.equipment_legs = null
		Equipment.Slot.OFFHAND:
			if stats.hand_left == eq: stats.hand_left = null
			elif stats.hand_right == eq: stats.hand_right = null


func _on_equipment_button_pressed() -> void:
	if not interactive:
		return
	# Blocking takes precedence: when an enemy is attacking, a click defends.
	if is_blocking:
		attempt_to_block()
	elif can_use_active_ability():
		attempt_to_use_ability()


func _on_mouse_entered() -> void:
	if not equipment:
		return
	_set_hovered(true)
	var anchor_rect := Rect2(global_position, size)
	Events.inventory_preview_show_requested.emit(null, equipment, anchor_rect)


func _on_mouse_exited() -> void:
	_set_hovered(false)
	Events.inventory_preview_hide_requested.emit()


func _set_hovered(value: bool) -> void:
	hover_glow_panel.visible = value
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(equipment_button, "scale", HOVER_SCALE if value else Vector2.ONE, HOVER_TWEEN_TIME)
