class_name WeaponCard
extends Control

@onready var weapon_ui: WeaponUI = $WeaponUI
@onready var rarity: TextureRect = $Rarity
@onready var text_box: RichTextLabel = $TextBox
@onready var name_label: RichTextLabel = $NameLabel
@onready var type_label: RichTextLabel = $TypeLabel

@export var weapon: Weapon : set = set_weapon

#func _ready() -> void:


func set_weapon(new_weapon: Weapon) -> void:
	weapon= new_weapon
	weapon_ui.set_weapon(weapon)
	text_box.text = weapon.get_tooltip()
	name_label.text = weapon.weapon_name
	rarity.modulate = Card.RARITY_COLORS[weapon.rarity]
	type_label.text = Weapon.Type.keys()[weapon.type]
	
