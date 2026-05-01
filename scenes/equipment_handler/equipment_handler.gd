class_name EquipmentHandler
extends Control

## Per-slot equipment handler. Listens for incoming attacks (enemy_attack_declared)
## and lets the player click this slot to consume its block value into player.stats.block.
## After being clicked once during an attack, it greys out until the next incoming attack.

signal equipment_destroyed(equipment: Equipment)

@export var owner_of_equipment: Node
@onready var equipment_ui: EquipmentUI = $EquipmentButton/EquipmentUI
@onready var equipment_button: Button = %EquipmentButton

var equipment: Equipment
var is_blocking: bool = false

func _ready() -> void:
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.player_blocks_declared.connect(_on_player_blocks_declared)


func set_equipment(new_equipment: Equipment) -> void:
	if not is_node_ready():
		await ready
	if new_equipment:
		equipment_ui.equipment = new_equipment
		equipment = equipment_ui.equipment
		equipment.owner = owner_of_equipment
		equipment.initialize_equipment(owner_of_equipment)
		show()
		_refresh_button_state()
	else:
		equipment = null
		equipment_ui.equipment = null
		hide()


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


func _refresh_button_state() -> void:
	if not equipment:
		equipment_button.disabled = true
		equipment_ui.set_grey_out(true)
		return
	var available := can_block()
	equipment_button.disabled = not available
	equipment_ui.set_grey_out(not available)
	equipment_ui.update_block_label()


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

	flash()

	if equipment.is_destroyed():
		_destroy_equipment()
	else:
		_refresh_button_state()


func _destroy_equipment() -> void:
	var destroyed := equipment
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
	attempt_to_block()


func _on_mouse_entered() -> void:
	if equipment:
		Events.card_tooltip_requested.emit(equipment.icon, equipment.get_tooltip())


func _on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
