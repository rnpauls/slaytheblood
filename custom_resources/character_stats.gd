class_name CharacterStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture

@export_group("Gameplay Data")
@export var starting_deck: CardPile
@export var draftable_cards: CardPile
@export var cards_per_turn: int
#@export var max_mana: int
@export var starting_relic: Relic

var mana: int : set = set_mana
var action_points: int : set = set_action_points
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile

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

func take_damage(damage : int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()

func can_play_card(card:Card) -> bool:
	return mana >= card.cost and action_points >= 1

func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	instance.reset_action_points()
	instance.deck = instance.starting_deck.duplicate()
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	return instance
