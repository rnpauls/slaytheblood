class_name ShopCard
extends VBoxContainer

@export var card: Card : set = set_card

@onready var card_container: Control = %CardContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var current_card_ui: CardMenuUI = $CardContainer/CardMenuUI
@onready var gold_cost := RNG.instance.randi_range(100,300)

func _ready():
	update(preload("res://test_data/test_run_stats.tres"))

func update(run_stats: RunStats) -> void:
	if not card_container or not price or not buy_button:
		return
	
	price_label.text = str(gold_cost)
	
	if run_stats.gold >= gold_cost:
		price_label.remove_theme_color_override("font_color")
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color.RED)
		buy_button.disabled = true

func set_card(new_card: Card) -> void:
	if not is_node_ready():
		await ready
	card = new_card
	current_card_ui.card = card

func _on_buy_button_pressed() -> void:
	Events.shop_card_bought.emit(card, gold_cost)
	card_container.queue_free()
	price.queue_free()
	buy_button.queue_free()
