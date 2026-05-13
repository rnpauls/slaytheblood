class_name InventoryCard
extends Control

const HANDS_LABELS := {
	Weapon.Hands.ONEHAND: "One-Handed",
	Weapon.Hands.TWOHAND: "Two-Handed",
	Weapon.Hands.OFFHAND: "Off-Hand",
}

const WARNING_BADGE_PATH := "res://art/equipment_badges/warning.png"
const INFINITY_BADGE_PATH := "res://art/equipment_badges/infinity.png"

@onready var weapon_ui: WeaponUI = $ArtPanel/WeaponUI
@onready var equipment_display: Control = $ArtPanel/EquipmentDisplay
@onready var equip_icon: TextureRect = $ArtPanel/EquipmentDisplay/EquipIcon
@onready var block_label: Label = $ArtPanel/EquipmentDisplay/BlockBadge/BlockLabel
@onready var one_shot_badge: TextureRect = $ArtPanel/EquipmentDisplay/OneShotBadge
@onready var filigree: TextureRect = %Filigree
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
	filigree.modulate = Constants.RARITY_COLORS[weapon.rarity]
	type_label.text = "%s - %s" % [
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
	# Normalize the -1 sentinel for display (pre-clone .tres in reward screen).
	var display_block: int = equipment.current_block if equipment.current_block >= 0 else equipment.max_block
	block_label.text = "%d/%d" % [display_block, equipment.max_block]
	_update_status_badge()
	text_box.text = IconRegistry.expand_icons(KeywordRegistry.format_keywords(equipment.get_tooltip()))
	name_label.text = equipment.equipment_name
	filigree.modulate = Constants.RARITY_COLORS[equipment.rarity]
	type_label.text = Equipment.Slot.keys()[equipment.slot]


func _update_status_badge() -> void:
	if equipment.regenerates_each_battle and equipment.unbreakable:
		one_shot_badge.texture = _load_badge(INFINITY_BADGE_PATH)
		one_shot_badge.visible = one_shot_badge.texture != null
	elif equipment.single_use or equipment.current_block == 1:
		one_shot_badge.texture = _load_badge(WARNING_BADGE_PATH)
		one_shot_badge.visible = one_shot_badge.texture != null
	else:
		one_shot_badge.visible = false


func _load_badge(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null
