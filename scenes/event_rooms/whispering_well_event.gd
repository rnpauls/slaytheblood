extends EventRoom

const ECHOING_COIN := preload("res://relics/echoing_coin.tres")
const GOLD_TRIBUTE := 100

@onready var blood_button: EventRoomButton = %BloodButton
@onready var gold_button: EventRoomButton = %GoldButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()

	var already_owned := relic_handler and relic_handler.has_relic(ECHOING_COIN.id)
	blood_button.disabled = already_owned or character_stats.health <= 1
	gold_button.disabled = already_owned or run_stats.gold < GOLD_TRIBUTE
	if not already_owned:
		blood_button.relic_preview = ECHOING_COIN
		gold_button.relic_preview = ECHOING_COIN

	blood_button.event_button_callback = drop_blood
	gold_button.event_button_callback = drop_gold
	leave_button.event_button_callback = skip


func drop_blood() -> void:
	var lost := character_stats.health / 2
	character_stats.set_health(character_stats.health - lost)
	if relic_handler:
		relic_handler.add_relic(ECHOING_COIN)
	resolve("Your blood drips into the dark. A coin spirals up out of the well. Gained Echoing Coin.")


func drop_gold() -> void:
	run_stats.gold -= GOLD_TRIBUTE
	if relic_handler:
		relic_handler.add_relic(ECHOING_COIN)
	resolve("Coins clatter down into the dark. One echoes back. Gained Echoing Coin.")
