class_name InventoryView
extends Control

const WEAPON_CARD_RENDER_CONTAINER_SCENE := preload("res://scenes/weapon_handler/weapon_card_render_container.tscn")

@export var inventory: Inventory

@onready var title: Label = %Title
@onready var weapons: GridContainer = %Weapons
@onready var back_button: Button = %BackButton
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup

func _ready() -> void:
	back_button.pressed.connect(hide)
	
	for weapon: WeaponCardRenderContainer in weapons.get_children():
		weapon.queue_free()
	
	#card_tooltip_popup.hide_tooltip()
	#_update_view()

func _input(event:InputEvent) ->void:
	if event.is_action_pressed("ui_cancel"):
		if card_tooltip_popup.visible:
			card_tooltip_popup.hide_tooltip()
		else:
			hide()

func show_current_view() ->void:
	for weapon: WeaponCardRenderContainer in weapons.get_children():
		weapon.queue_free()
	
	card_tooltip_popup.hide_tooltip()
	#title.text = new_title
	_update_view.call_deferred()

func _update_view() ->void:
	if not inventory:
		return
	
	var all_weapons := inventory.weapons.duplicate()
	
	for weapon: Weapon in all_weapons:
		var new_weapon := WEAPON_CARD_RENDER_CONTAINER_SCENE.instantiate() as WeaponCardRenderContainer
		weapons.add_child(new_weapon)
		new_weapon.weapon = weapon
		#new_weapon.tooltip_requested.connect(card_tooltip_popup.show_tooltip)
	
	show()
