class_name InventoryCard
extends Control

@onready var weapon_ui: WeaponUI = $WeaponUI
@onready var equipment_display: Control = $EquipmentDisplay
@onready var equip_icon: TextureRect = $EquipmentDisplay/EquipIcon
@onready var block_label: Label = $EquipmentDisplay/BlockBadge/BlockLabel
@onready var rarity: TextureRect = $Rarity
@onready var text_box: RichTextLabel = $TextBox
@onready var name_label: RichTextLabel = $NameLabel
@onready var type_label: RichTextLabel = $TypeLabel

@export var weapon: Weapon : set = set_weapon
@export var equipment: Equipment : set = set_equipment


func set_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	if not is_node_ready():
		await ready
	if not weapon:
		return
	weapon_ui.show()
	equipment_display.hide()
	weapon_ui.set_weapon(weapon)
	text_box.text = IconRegistry.expand_icons(KeywordRegistry.format_keywords(weapon.get_tooltip()))
	name_label.text = weapon.weapon_name
	rarity.modulate = Weapon.RARITY_COLORS[weapon.rarity]
	type_label.text = Weapon.Type.keys()[weapon.type]


func set_equipment(new_equipment: Equipment) -> void:
	equipment = new_equipment
	if not is_node_ready():
		await ready
	if not equipment:
		return
	weapon_ui.hide()
	equipment_display.show()
	equip_icon.texture = equipment.icon
	block_label.text = str(equipment.max_block)
	text_box.text = IconRegistry.expand_icons(KeywordRegistry.format_keywords(equipment.get_tooltip()))
	name_label.text = equipment.equipment_name
	rarity.modulate = Equipment.RARITY_COLORS[equipment.rarity]
	type_label.text = Equipment.Slot.keys()[equipment.slot]
