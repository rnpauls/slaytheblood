class_name ShopWeapon
extends VBoxContainer

const WEAPON_CARD_RENDER_CONTAINER = preload("res://scenes/weapon_handler/weapon_card_render_container.tscn")

@export var weapon: Weapon : set = set_weapon

@onready var weapon_container: MarginContainer = %WeaponContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var gold_cost := RNG.instance.randi_range(100,300)

func _ready():
	update(preload("res://test_data/test_run_stats.tres"))

func update(run_stats: RunStats) -> void:
	if not weapon_container or not price or not buy_button:
		return
	
	price_label.text = str(gold_cost)
	
	if run_stats.gold >= gold_cost:
		price_label.remove_theme_color_override("font_color")
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color.RED)
		buy_button.disabled = true

func set_weapon(new_weapon: Weapon) -> void:
	if not is_node_ready():
		await ready

	weapon = new_weapon
	
	for weapon_card: WeaponCard in weapon_container.get_children():
		weapon_card.queue_free()
	
	var new_weapon_card := WEAPON_CARD_RENDER_CONTAINER.instantiate() as WeaponCardRenderContainer
	weapon_container.add_child(new_weapon_card)
	new_weapon_card.weapon = weapon
	#current_weapon_card = new_weapon_card

func _on_buy_button_pressed() -> void:
	Events.shop_weapon_bought.emit(weapon, gold_cost)
	weapon_container.queue_free()
	price.queue_free()
	buy_button.queue_free()
