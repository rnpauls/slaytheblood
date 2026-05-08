extends EventRoom

const PRAY_HP_COST := 8
const DEFILE_MAX_HP_GAIN := 12

@onready var pray_button: EventRoomButton = %PrayButton
@onready var defile_button: EventRoomButton = %DefileButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()
	pray_button.disabled = character_stats.health <= PRAY_HP_COST
	defile_button.disabled = run_stats.gold <= 0

	pray_button.event_button_callback = pray
	defile_button.event_button_callback = defile
	leave_button.event_button_callback = skip


func pray() -> void:
	character_stats.set_health(character_stats.health - PRAY_HP_COST)
	var card := random_card_of_rarity(Card.Rarity.RARE)
	if not card:
		resolve("The shrine drinks your blood, but offers nothing in return.")
		return
	character_stats.deck.add_card(card)
	resolve("Your sacrifice is accepted. You gained %s." % format_card_name(card))


func defile() -> void:
	var lost := run_stats.gold / 2
	run_stats.gold -= lost
	character_stats.max_health += DEFILE_MAX_HP_GAIN
	resolve("You scatter %d gold across the altar. Max HP +%d." % [lost, DEFILE_MAX_HP_GAIN])
