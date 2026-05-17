class_name EventRoom
extends Node

@export var character_stats: CharacterStats
@export var run_stats: RunStats
## Injected by run.gd. Lets events grant relics via relic_handler.add_relic().
## Optional — events that don't grant relics can leave this null.
@export var relic_handler: RelicHandler

@export_group("Resolution UI")
@export var background: TextureRect
@export var choice_container: Control
@export var resolution_container: Control
@export var resolution_label: Label
@export var continue_button: EventRoomButton

func setup() -> void:
	if continue_button:
		continue_button.event_button_callback = skip
	if resolution_container:
		resolution_container.hide()

func resolve(text: String, new_background: Texture2D = null) -> void:
	if choice_container:
		choice_container.hide()
	if resolution_container:
		resolution_container.show()
	if resolution_label:
		resolution_label.text = text
	if new_background and background:
		background.texture = new_background

func skip() -> void:
	Events.event_room_exited.emit()

func random_card_of_rarity(rarity: Card.Rarity) -> Card:
	if not character_stats or not character_stats.draftable_cards:
		return null
	var pool: Array[Card] = []
	for c: Card in character_stats.draftable_cards.cards:
		if c.rarity == rarity:
			pool.append(c)
	if pool.is_empty():
		return null
	var picked: Card = RNG.array_pick_random(pool)
	return picked.duplicate() as Card

func format_card_name(card: Card) -> String:
	if not card:
		return ""
	return card.id.capitalize()
