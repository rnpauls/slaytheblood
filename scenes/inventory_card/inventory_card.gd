class_name InventoryCard
extends Control

const HANDS_LABELS := {
	Weapon.Hands.ONEHAND: "One-Handed",
	Weapon.Hands.TWOHAND: "Two-Handed",
	Weapon.Hands.OFFHAND: "Off-Hand",
}

@onready var weapon_ui: WeaponUI = $ArtPanel/WeaponUI
@onready var equipment_display: Control = $ArtPanel/EquipmentDisplay
@onready var equip_icon: TextureRect = $ArtPanel/EquipmentDisplay/EquipIcon
@onready var block_label: Label = $ArtPanel/EquipmentDisplay/BlockBadge/BlockLabel
@onready var one_shot_badge: TextureRect = $ArtPanel/EquipmentDisplay/OneShotBadge
@onready var rarity: TextureRect = $Rarity
@onready var text_box: RichTextLabel = $TextBox
@onready var name_label: RichTextLabel = $ArtPanel/NameLabel
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
	type_label.text = "%s\n[font_size=20]%s[/font_size]" % [
		Weapon.Type.keys()[weapon.type],
		HANDS_LABELS[weapon.hands],
	]


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
	one_shot_badge.visible = equipment.persistence == Equipment.Persistence.ONE_SHOT
	text_box.text = IconRegistry.expand_icons(KeywordRegistry.format_keywords(equipment.get_tooltip()))
	name_label.text = equipment.equipment_name
	rarity.modulate = Equipment.RARITY_COLORS[equipment.rarity]
	type_label.text = Equipment.Slot.keys()[equipment.slot]
