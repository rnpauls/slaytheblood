class_name InventoryView
extends Control

const INVENTORY_CARD_RENDER_CONTAINER_SCENE := preload("res://scenes/inventory_card/inventory_card_render_container.tscn")
const WEAPON_HANDLER_SCENE := preload("res://scenes/weapon_handler/weapon_handler.tscn")
const EQUIPMENT_HANDLER_SCENE := preload("res://scenes/equipment_handler/equipment_handler.tscn")

const SLOT_SIZE := Vector2(64, 64)
# Positions mirror the paper-doll layout in battle.tscn, normalized so the
# leftmost slot (L. Hand at battle x=47) sits at x=0 here.
const LOADOUT_POSITIONS := {
	"head":  Vector2(99, 0),
	"arms":  Vector2(29, 70),
	"chest": Vector2(99, 70),
	"legs":  Vector2(169, 70),
	"lhand": Vector2(0, 177),
	"rhand": Vector2(219, 177),
}

@export var inventory: Inventory
## Optional: when set, the view shows equipped slots and supports click-to-equip/unequip.
@export var character: CharacterStats
## When true, equip/unequip clicks are disabled (set by Run while in battle).
@export var combat_locked: bool = false

@onready var title: Label = %Title
@onready var loadout: Control = %Loadout
@onready var pool: GridContainer = %Pool
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(hide)
	# Hiding the view doesn't reliably fire mouse_exited on the card hover
	# sources inside it, so clear any tooltip whenever the view becomes hidden.
	visibility_changed.connect(_on_visibility_changed)
	_clear_view()


func _clear_view() -> void:
	for child in loadout.get_children():
		child.queue_free()
	for child in pool.get_children():
		child.queue_free()


func _on_visibility_changed() -> void:
	if not visible:
		Events.tooltip_hide_requested.emit()


func _input(event:InputEvent) ->void:
	if event.is_action_pressed("ui_cancel"):
		hide()


func show_current_view() ->void:
	_clear_view()
	_update_view.call_deferred()


func _update_view() ->void:
	if not inventory:
		return
	_build_loadout()
	_build_pool()
	show()


func _build_loadout() -> void:
	if not character:
		return
	_place_slot("arms",  character.equipment_arms, "Arms")
	_place_slot("chest", character.equipment_chest, "Chest")
	_place_slot("legs",  character.equipment_legs, "Legs")
	_place_slot("lhand", character.hand_left, "L. Hand")
	_place_slot("rhand", character.hand_right, "R. Hand")
	# Head added last so it draws on top — its hover glow overflows downward
	# into the chest's area and would otherwise be hidden behind it.
	_place_slot("head",  character.equipment_head, "Head")


func _place_slot(slot_key: String, item: Resource, slot_label: String) -> void:
	var pos: Vector2 = LOADOUT_POSITIONS[slot_key]
	if item == null:
		var slot := _make_empty_slot(slot_label)
		slot.position = pos
		loadout.add_child(slot)
	elif item is Weapon:
		_add_weapon_handler(item, pos)
	elif item is Equipment:
		_add_equipment_handler(item, pos)


# add_child must precede any access to the handler's @onready vars
# (weapon_button / equipment_button) — they only resolve once _ready fires.
func _add_weapon_handler(w: Weapon, pos: Vector2) -> void:
	var h := WEAPON_HANDLER_SCENE.instantiate() as WeaponHandler
	h.interactive = false
	h.position = pos
	loadout.add_child(h)
	h.set_weapon(w)
	h.weapon_button.disabled = combat_locked
	h.weapon_button.pressed.connect(_on_loadout_pressed.bind(w))


func _add_equipment_handler(eq: Equipment, pos: Vector2) -> void:
	var h := EQUIPMENT_HANDLER_SCENE.instantiate() as EquipmentHandler
	h.interactive = false
	h.position = pos
	loadout.add_child(h)
	h.set_equipment(eq)
	h.equipment_button.disabled = combat_locked
	h.equipment_button.pressed.connect(_on_loadout_pressed.bind(eq))


func _make_empty_slot(slot_label: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.size = SLOT_SIZE
	panel.modulate = Color(1, 1, 1, 0.35)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = slot_label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	return panel


func _build_pool() -> void:
	var equipped := _equipped_items()
	for w: Weapon in inventory.weapons.duplicate():
		if w in equipped:
			continue
		pool.add_child(_make_pool_card(w))
	for eq: Equipment in inventory.equips.duplicate():
		if eq in equipped:
			continue
		pool.add_child(_make_pool_card(eq))


func _equipped_items() -> Array:
	if not character:
		return []
	var items: Array = []
	for slot in [character.equipment_head, character.equipment_chest,
				 character.equipment_arms, character.equipment_legs,
				 character.hand_left, character.hand_right]:
		if slot != null:
			items.append(slot)
	return items


func _make_pool_card(item: Resource) -> InventoryCardRenderContainer:
	var c := INVENTORY_CARD_RENDER_CONTAINER_SCENE.instantiate() as InventoryCardRenderContainer
	if item is Weapon:
		c.weapon = item
	elif item is Equipment:
		c.equipment = item
	# Equip/unequip is only allowed outside combat — in battle the view is
	# read-only.
	if character and not combat_locked:
		c.clickable = true
		c.pressed.connect(_on_pool_pressed)
	return c


func _on_loadout_pressed(item: Resource) -> void:
	if combat_locked or not character:
		return
	_unequip(item)
	show_current_view()


func _on_pool_pressed(item: Resource) -> void:
	if combat_locked or not character:
		return
	if _is_equipped(item):
		_unequip(item)
	elif item is Equipment:
		_equip_equipment(item)
	elif item is Weapon:
		_equip_weapon(item)
	show_current_view()


func _is_equipped(item: Resource) -> bool:
	return item == character.equipment_head \
		or item == character.equipment_chest \
		or item == character.equipment_arms \
		or item == character.equipment_legs \
		or item == character.hand_left \
		or item == character.hand_right


func _equip_equipment(eq: Equipment) -> void:
	match eq.slot:
		Equipment.Slot.HEAD: character.equipment_head = eq
		Equipment.Slot.CHEST: character.equipment_chest = eq
		Equipment.Slot.ARMS: character.equipment_arms = eq
		Equipment.Slot.LEGS: character.equipment_legs = eq
		Equipment.Slot.OFFHAND: _equip_to_hand(eq)


func _equip_weapon(w: Weapon) -> void:
	_equip_to_hand(w)


func _equip_to_hand(item: Resource) -> void:
	if character.hand_left == null:
		character.hand_left = item
	elif character.hand_right == null:
		character.hand_right = item
	else:
		character.hand_left = item


func _unequip(item: Resource) -> void:
	if character.equipment_head == item: character.equipment_head = null
	elif character.equipment_chest == item: character.equipment_chest = null
	elif character.equipment_arms == item: character.equipment_arms = null
	elif character.equipment_legs == item: character.equipment_legs = null
	elif character.hand_left == item: character.hand_left = null
	elif character.hand_right == item: character.hand_right = null
