class_name HelpfulBoyEvent
extends EventRoom

@onready var duplicate_last_card_button: EventRoomButton = %DuplicateLastCardButton
@onready var plus_max_hp_button: EventRoomButton = %PlusMaxHPButton


func setup() -> void:
	super.setup()
	duplicate_last_card_button.disabled = character_stats.deck.cards.is_empty()
	duplicate_last_card_button.event_button_callback = duplicate_last_card
	plus_max_hp_button.event_button_callback = plus_max_hp


func duplicate_last_card() -> void:
	var copy: Card = character_stats.deck.cards[-1].duplicate()
	character_stats.deck.add_card(copy)
	resolve("The boy slips a copy of %s into your deck." % format_card_name(copy))


func plus_max_hp() -> void:
	character_stats.max_health += 5
	resolve("You feel hardier. Max HP is now %d." % character_stats.max_health)
