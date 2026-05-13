class_name ShopEquipment
extends VBoxContainer

@export var equipment: Equipment : set = set_equipment

@onready var equipment_container: MarginContainer = %EquipmentContainer
@onready var current_inventory_card: InventoryCardRenderContainer = %InventoryCardRenderContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var gold_cost := RNG.instance.randi_range(75, 250)

func _ready():
	update(preload("res://test_data/test_run_stats.tres"))

func update(run_stats: RunStats) -> void:
	if not equipment_container or not price or not buy_button:
		return

	price_label.text = str(gold_cost)

	if run_stats.gold >= gold_cost:
		price_label.remove_theme_color_override("font_color")
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color.RED)
		buy_button.disabled = true

func set_equipment(new_equipment: Equipment) -> void:
	if not is_node_ready():
		await ready

	equipment = new_equipment
	current_inventory_card.equipment = equipment

func _on_buy_button_pressed() -> void:
	Events.shop_equipment_bought.emit(equipment, gold_cost)
	equipment_container.queue_free()
	price.queue_free()
	buy_button.queue_free()
