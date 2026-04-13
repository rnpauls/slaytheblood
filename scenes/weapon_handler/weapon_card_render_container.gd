class_name WeaponCardRenderContainer
extends MarginContainer

@onready var weapon_card: WeaponCard = $SubViewport/WeaponCard
@export var weapon: Weapon : set = set_weapon

func set_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	weapon_card.weapon = weapon
