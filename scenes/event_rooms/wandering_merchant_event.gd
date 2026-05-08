extends EventRoom

const COMMON_COST := 75
const UNCOMMON_COST := 150

@onready var common_button: EventRoomButton = %CommonButton
@onready var uncommon_button: EventRoomButton = %UncommonButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()
	common_button.disabled = run_stats.gold < COMMON_COST
	uncommon_button.disabled = run_stats.gold < UNCOMMON_COST

	common_button.event_button_callback = buy_common
	uncommon_button.event_button_callback = buy_uncommon
	leave_button.event_button_callback = skip


func buy_common() -> void:
	_purchase(Card.Rarity.COMMON, COMMON_COST)


func buy_uncommon() -> void:
	_purchase(Card.Rarity.UNCOMMON, UNCOMMON_COST)


func _purchase(rarity: Card.Rarity, cost: int) -> void:
	var card := random_card_of_rarity(rarity)
	if not card:
		resolve("The merchant has nothing of that rarity to offer.")
		return
	run_stats.gold -= cost
	character_stats.deck.add_card(card)
	resolve("You bought %s for %d gold." % [format_card_name(card), cost])
