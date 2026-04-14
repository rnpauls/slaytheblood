class_name WeaponCardRender
extends Node2D

@onready var weapon_card: WeaponCard = $SubViewportContainer/SubViewport/WeaponCard
@export var weapon: Weapon : set = set_weapon

func set_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	weapon_card.weapon = weapon
