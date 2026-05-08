extends EventRoom

const BURN_GOLD := 75

@onready var read_button: EventRoomButton = %ReadButton
@onready var burn_button: EventRoomButton = %BurnButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()
	read_button.event_button_callback = read_tome
	burn_button.event_button_callback = burn_tome
	leave_button.event_button_callback = skip


func read_tome() -> void:
	var card := random_card_of_rarity(Card.Rarity.UNCOMMON)
	if not card:
		resolve("The pages whisper, but no spell takes hold.")
		return
	character_stats.deck.add_card(card)
	resolve("The whispers settle into your memory. You gained %s." % format_card_name(card))


func burn_tome() -> void:
	run_stats.gold += BURN_GOLD
	resolve("The tome burns blue and crumbles. You scrape %d gold from the ashes." % BURN_GOLD)
