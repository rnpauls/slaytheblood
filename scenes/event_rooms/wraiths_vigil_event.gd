extends EventRoom

const WRAITHS_VIGIL := preload("res://relics/wraiths_vigil.tres")
const RESPECT_HP_COST := 5
const TAKE_HP_COST := 10

@onready var respect_button: EventRoomButton = %RespectButton
@onready var take_button: EventRoomButton = %TakeButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()

	var already_owned := relic_handler and relic_handler.has_relic(WRAITHS_VIGIL.id)
	respect_button.disabled = already_owned or character_stats.health <= RESPECT_HP_COST
	if not already_owned:
		respect_button.relic_preview = WRAITHS_VIGIL

	take_button.disabled = character_stats.health <= TAKE_HP_COST

	respect_button.event_button_callback = pay_respects
	take_button.event_button_callback = take_sword
	leave_button.event_button_callback = skip


func pay_respects() -> void:
	character_stats.set_health(character_stats.health - RESPECT_HP_COST)
	if relic_handler:
		relic_handler.add_relic(WRAITHS_VIGIL)
	resolve("The knight bows his head. Cold settles into your bones. Gained Wraith's Vigil.")


func take_sword() -> void:
	character_stats.set_health(character_stats.health - TAKE_HP_COST)
	var card := random_card_of_rarity(Card.Rarity.RARE)
	if not card:
		resolve("You pry the sword loose — but it crumbles to rust in your grip.")
		return
	character_stats.deck.add_card(card)
	resolve("The blade's memory flows into your hand. You gained %s." % format_card_name(card))
