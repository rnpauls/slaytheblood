class_name EquipmentView
extends Control

const EQUIPMENT_RENDER_SCENE := preload("res://scenes/equipment_handler/equipment_card_render_container.tscn")

@export var character: CharacterStats : set = set_character

@onready var title: Label = %Title
@onready var head_slot: Control = %HeadSlot
@onready var chest_slot: Control = %ChestSlot
@onready var arms_slot: Control = %ArmsSlot
@onready var legs_slot: Control = %LegsSlot
@onready var offhand_slot: Control = %OffhandSlot
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var back_button: Button = %BackButton
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup

func _ready() -> void:
	back_button.pressed.connect(hide)
	for slot in [head_slot, chest_slot, arms_slot, legs_slot, offhand_slot]:
		_clear_container(slot)
	_clear_container(inventory_grid)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if card_tooltip_popup and card_tooltip_popup.visible:
			card_tooltip_popup.hide_tooltip()
		else:
			hide()


func set_character(value: CharacterStats) -> void:
	character = value


func show_current_view() -> void:
	if card_tooltip_popup:
		card_tooltip_popup.hide_tooltip()
	_refresh.call_deferred()
	show()


func _refresh() -> void:
	if not character:
		return
	_render_slot(head_slot, character.equipment_head, _on_unequip_body.bind(Equipment.Slot.HEAD))
	_render_slot(chest_slot, character.equipment_chest, _on_unequip_body.bind(Equipment.Slot.CHEST))
	_render_slot(arms_slot, character.equipment_arms, _on_unequip_body.bind(Equipment.Slot.ARMS))
	_render_slot(legs_slot, character.equipment_legs, _on_unequip_body.bind(Equipment.Slot.LEGS))
	_render_slot(offhand_slot, _get_equipped_offhand(), _on_unequip_offhand)
	_render_inventory()


func _get_equipped_offhand() -> Equipment:
	if character.hand_left is Equipment:
		return character.hand_left
	if character.hand_right is Equipment:
		return character.hand_right
	return null


func _render_slot(container: Control, eq: Equipment, on_pressed: Callable) -> void:
	_clear_container(container)
	if not eq:
		return
	var render := EQUIPMENT_RENDER_SCENE.instantiate() as EquipmentCardRenderContainer
	container.add_child(render)
	render.equipment = eq
	render.pressed.connect(on_pressed)
	if card_tooltip_popup:
		render.tooltip_requested.connect(card_tooltip_popup.show_tooltip)


func _render_inventory() -> void:
	_clear_container(inventory_grid)
	if not character or not character.inventory:
		return
	# Only show equipment NOT currently equipped.
	var equipped := _all_equipped_set()
	for eq: Equipment in character.inventory.equips:
		if eq in equipped:
			continue
		var render := EQUIPMENT_RENDER_SCENE.instantiate() as EquipmentCardRenderContainer
		inventory_grid.add_child(render)
		render.equipment = eq
		render.pressed.connect(_on_inventory_item_clicked)
		if card_tooltip_popup:
			render.tooltip_requested.connect(card_tooltip_popup.show_tooltip)


func _all_equipped_set() -> Array:
	var s: Array = []
	for eq in [character.equipment_head, character.equipment_chest, character.equipment_arms, character.equipment_legs]:
		if eq: s.append(eq)
	if character.hand_left is Equipment: s.append(character.hand_left)
	if character.hand_right is Equipment: s.append(character.hand_right)
	return s


func _on_inventory_item_clicked(eq: Equipment) -> void:
	# Equip into the matching slot, displacing whatever was there.
	match eq.slot:
		Equipment.Slot.HEAD:
			character.equipment_head = eq
		Equipment.Slot.CHEST:
			character.equipment_chest = eq
		Equipment.Slot.ARMS:
			character.equipment_arms = eq
		Equipment.Slot.LEGS:
			character.equipment_legs = eq
		Equipment.Slot.OFFHAND:
			# Prefer left hand; if it holds a Weapon, that weapon stays in inventory but is unequipped.
			if character.hand_left == null:
				character.hand_left = eq
			elif character.hand_right == null:
				character.hand_right = eq
			else:
				# Both hands occupied — replace left.
				character.hand_left = eq
	_refresh()


func _on_unequip_body(_eq: Equipment, slot: Equipment.Slot) -> void:
	match slot:
		Equipment.Slot.HEAD: character.equipment_head = null
		Equipment.Slot.CHEST: character.equipment_chest = null
		Equipment.Slot.ARMS: character.equipment_arms = null
		Equipment.Slot.LEGS: character.equipment_legs = null
	_refresh()


func _on_unequip_offhand(_eq: Equipment) -> void:
	if character.hand_left is Equipment:
		character.hand_left = null
	elif character.hand_right is Equipment:
		character.hand_right = null
	_refresh()


func _clear_container(node: Node) -> void:
	if not node:
		return
	for child in node.get_children():
		child.queue_free()
