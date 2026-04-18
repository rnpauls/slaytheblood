class_name WeaponCardRenderContainer
extends MarginContainer

@export var weapon: Weapon : set = set_weapon

@onready var sub_viewport_viewer: TextureRect = %SubViewportViewer
@onready var weapon_card: WeaponCard = $SubViewport/WeaponCard
@onready var sub_viewport: SubViewport = %SubViewport

func _ready() -> void:
	sub_viewport_viewer.texture = sub_viewport.get_texture()
func set_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	weapon_card.weapon = weapon
