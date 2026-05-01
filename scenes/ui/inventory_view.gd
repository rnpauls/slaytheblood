class_name InventoryView
extends Control

const WEAPON_CARD_RENDER_CONTAINER_SCENE := preload("res://scenes/weapon_handler/weapon_card_render_container.tscn")
const EQUIPMENT_RENDER_SCENE := preload("res://scenes/equipment_handler/equipment_card_render_container.tscn")

@export var inventory: Inventory
## Optional: when set, the view shows equipped slots and supports click-to-equip/unequip.
@export var character: CharacterStats

@onready var title: Label = %Title
@onready var weapons: GridContainer = %Weapons
@onready var back_button: Button = %BackButton
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup

func _ready() -> void:
	back_button.pressed.connect(hide)

	for child in weapons.get_children():
		child.queue_free()


func _input(event:InputEvent) ->void:
	if event.is_action_pressed("ui_cancel"):
		if card_tooltip_popup.visible:
			card_tooltip_popup.hide_tooltip()
		else:
			hide()


func show_current_view() ->void:
	for child in weapons.get_children():
		child.queue_free()

	card_tooltip_popup.hide_tooltip()
	_update_view.call_deferred()


func _update_view() ->void:
	if not inventory:
		return

	for w: Weapon in inventory.weapons.duplicate():
		var new_w := WEAPON_CARD_RENDER_CONTAINER_SCENE.instantiate() as WeaponCardRenderContainer
		weapons.add_child(new_w)
		new_w.weapon = w

	for eq: Equipment in inventory.equips.duplicate():
		var new_eq := EQUIPMENT_RENDER_SCENE.instantiate() as EquipmentCardRenderContainer
		weapons.add_child(new_eq)
		new_eq.equipment = eq
		if character:
			new_eq.pressed.connect(_on_equipment_clicked)
		new_eq.tooltip_requested.connect(card_tooltip_popup.show_tooltip)

	show()


## Click an equipment to equip it into its slot, displacing whatever was there
## (the displaced piece stays in the inventory pool, just unequipped).
## Click again on something already equipped → unequip.
func _on_equipment_clicked(eq: Equipment) -> void:
	if not character:
		return
	if _is_equipped(eq):
		_unequip(eq)
	else:
		_equip(eq)
	show_current_view()


func _is_equipped(eq: Equipment) -> bool:
	return eq == character.equipment_head \
		or eq == character.equipment_chest \
		or eq == character.equipment_arms \
		or eq == character.equipment_legs \
		or eq == character.hand_left \
		or eq == character.hand_right


func _equip(eq: Equipment) -> void:
	match eq.slot:
		Equipment.Slot.HEAD: character.equipment_head = eq
		Equipment.Slot.CHEST: character.equipment_chest = eq
		Equipment.Slot.ARMS: character.equipment_arms = eq
		Equipment.Slot.LEGS: character.equipment_legs = eq
		Equipment.Slot.OFFHAND:
			if character.hand_left == null:
				character.hand_left = eq
			elif character.hand_right == null:
				character.hand_right = eq
			else:
				character.hand_left = eq


func _unequip(eq: Equipment) -> void:
	if character.equipment_head == eq: character.equipment_head = null
	elif character.equipment_chest == eq: character.equipment_chest = null
	elif character.equipment_arms == eq: character.equipment_arms = null
	elif character.equipment_legs == eq: character.equipment_legs = null
	elif character.hand_left == eq: character.hand_left = null
	elif character.hand_right == eq: character.hand_right = null
