class_name Shop
extends Control

const SHOP_CARD = preload("res://scenes/shop/shop_card.tscn")
const SHOP_RELIC = preload("res://scenes/shop/shop_relic.tscn")
const SHOP_WEAPON = preload("res://scenes/shop/shop_weapon.tscn")

@export var shop_relics: Array[Relic]
@export var shop_weapons: Array[Weapon]
@export var char_stats: CharacterStats
@export var run_stats: RunStats
@export var relic_handler: RelicHandler
@export var inventory: Inventory

@onready var cards: HBoxContainer = %Cards
@onready var relics: HBoxContainer = %Relics
@onready var weapons: HBoxContainer = %Weapons
@onready var shopkeeper_animation: AnimationPlayer = %ShopkeeperAnimation
@onready var blink_timer: Timer = %BlinkTimer
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup
@onready var modifier_handler: ModifierHandler = $ModifierHandler

func _ready() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.queue_free()
		
	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.queue_free()
	
	for shop_weapon: ShopWeapon in weapons.get_children():
		shop_weapon.queue_free()
		
	Events.shop_card_bought.connect(_on_shop_card_bought)
	Events.shop_relic_bought.connect(_on_shop_relic_bought)
	Events.shop_weapon_bought.connect(_on_shop_weapon_bought)

	_blink_timer_setup()
	blink_timer.timeout.connect(_on_blink_timer_timeout)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and card_tooltip_popup.visible:
		card_tooltip_popup.hide_tooltip()

func populate_shop() -> void:
	_generate_shop_cards()
	_generate_shop_relics()
	_generate_shop_weapons()

func _blink_timer_setup() -> void:
	blink_timer.wait_time = randf_range(1.0, 5.0)
	blink_timer.start()

func _generate_shop_cards() -> void:
	var shop_card_array: Array[Card] = []
	#var available_cards: Array[Card] = char_stats.draftable_cards.duplicate_cards()
	var available_cards:= char_stats.draftable_cards.duplicate_cards()
	RNG.array_shuffle(available_cards)
	#available_cards.shuffle()
	shop_card_array = available_cards.slice(0, 3)
	
	for card: Card in shop_card_array:
		var new_shop_card := SHOP_CARD.instantiate() as ShopCard
		cards.add_child(new_shop_card)
		new_shop_card.card = card
		new_shop_card.current_card_ui.tooltip_requested.connect(card_tooltip_popup.show_tooltip)
		new_shop_card.gold_cost = _get_updated_shop_cost(new_shop_card.gold_cost)
		new_shop_card.update(run_stats)


func _generate_shop_relics() -> void:
	var shop_relics_array: Array[Relic] = []
	var available_relics := shop_relics.filter(
		func(relic: Relic):
			var can_appear := relic.can_appear_as_reward(char_stats)
			var already_had_it := relic_handler.has_relic(relic.id)
			return can_appear and not already_had_it
	)
	
	RNG.array_shuffle(available_relics)
	#available_relics.shuffle()
	shop_relics_array = available_relics.slice(0, 3)
	
	for relic: Relic in shop_relics_array:
		var new_shop_relic := SHOP_RELIC.instantiate() as ShopRelic
		relics.add_child(new_shop_relic)
		new_shop_relic.relic = relic
		new_shop_relic.gold_cost = _get_updated_shop_cost(new_shop_relic.gold_cost)
		new_shop_relic.update(run_stats)

func _generate_shop_weapons() -> void:
	var shop_weapons_array: Array[Weapon] = []
	var available_weapons := shop_weapons.filter(
		func(weapon: Weapon):
			var can_appear := weapon.can_appear_as_reward(char_stats)
			var already_had_it := char_stats.inventory.has_weapon(weapon.id)
			return can_appear and not already_had_it
	)
	
	RNG.array_shuffle(available_weapons)
	#available_relics.shuffle()
	shop_weapons_array = available_weapons.slice(0, 3)
	
	for weapon: Weapon in shop_weapons_array:
		var new_shop_weapon := SHOP_WEAPON.instantiate() as ShopWeapon
		weapons.add_child(new_shop_weapon)
		new_shop_weapon.weapon = weapon
		new_shop_weapon.gold_cost = _get_updated_shop_cost(new_shop_weapon.gold_cost)
		new_shop_weapon.update(run_stats)

func _update_items() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.update(run_stats)
	
	for shop_weapon: ShopWeapon in weapons.get_children():
		shop_weapon.update(run_stats)

func _update_item_costs() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.gold_cost = _get_updated_shop_cost(shop_card.gold_cost)
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.gold_cost = _get_updated_shop_cost(shop_relic.gold_cost)
		shop_relic.update(run_stats)
	
	for shop_weapon: ShopWeapon in weapons.get_children():
		shop_weapon.gold_cost = _get_updated_shop_cost(shop_weapon.gold_cost)
		shop_weapon.update(run_stats)

func _get_updated_shop_cost(original_cost: int) -> int:
	return modifier_handler.get_modified_value(original_cost, Modifier.Type.SHOP_COST)

func _on_back_button_pressed() -> void:
	Events.shop_exited.emit()


func _on_shop_card_bought(card: Card, gold_cost: int) -> void:
	char_stats.deck.add_card(card)
	run_stats.gold -= gold_cost
	_update_items()

func _on_shop_relic_bought(relic: Relic, gold_cost: int) -> void:
	relic_handler.add_relic(relic)
	run_stats.gold -= gold_cost

	if relic is CouponsRelic:
		var coupons_relic := relic as CouponsRelic
		coupons_relic.add_shop_modifier(self)
		_update_item_costs()
	else:
		_update_items()

func _on_shop_weapon_bought(weapon: Weapon, gold_cost: int) -> void:
	char_stats.add_weapon(weapon)
	run_stats.gold -= gold_cost
	_update_items()

func _on_blink_timer_timeout() -> void:
	shopkeeper_animation.play("Blink")
	_blink_timer_setup()
