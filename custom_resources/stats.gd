class_name Stats
extends Resource

signal stats_changed

@export var character_name: String
@export var art: Texture

@export_group("Gameplay Data")
@export var max_health := 1 : set = set_max_health
@export var starting_deck: CardPile
@export var cards_per_turn: int

var mana: int : set = set_mana
var action_points: int : set = set_action_points
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile
var health: int : set = set_health
var block: int : set = set_block

func set_health(value : int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()

func set_max_health(value : int) -> void:
	var diff := value - max_health
	max_health = value
	
	if diff > 0:
		health += diff
	elif health > max_health:
		health = max_health
	
	stats_changed.emit()

func set_block(value : int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()

func set_mana(value: int) -> void:
	mana = value
	stats_changed.emit()
	
func set_action_points(value: int) -> void:
	action_points = value
	stats_changed.emit()

func reset_mana() -> void:
	mana = 0

func reset_action_points() -> void:
	action_points = 1

func can_play_card(card:Card) -> bool:
	return mana >= card.cost and action_points >= 1

func create_instance() -> Resource:
	var instance: Stats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	instance.reset_action_points()
	instance.deck = instance.starting_deck.duplicate()
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	return instance

func take_damage(damage : int) -> void:
	if damage <= 0:
		return
	var initial_damage = damage
	damage = clampi(damage - block, 0, damage)
	block = 0#clampi(block - initial_damage, 0, block)
	health -= damage

func heal(amount : int) -> void:
	health += amount

func mill(amount: int) -> Array[Card]:
	var milled_cards: Array[Card]
	for card_num in amount:
		var milled_card = draw_pile.draw_card()
		if milled_card:
			discard.add_card(milled_card)
			milled_cards.append(milled_card)
	return milled_cards
