extends EventRoom

const FORGED_CONDUIT := preload("res://relics/forged_conduit.tres")
const TRIBUTE_GOLD_COST := 100
## Don't let the player gut their deck below this size for the relic.
const MIN_DECK_SIZE_TO_FEED := 6

@onready var feed_button: EventRoomButton = %FeedButton
@onready var tribute_button: EventRoomButton = %TributeButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()

	var already_owned := relic_handler and relic_handler.has_relic(FORGED_CONDUIT.id)
	var deck_too_small := character_stats.deck.cards.size() < MIN_DECK_SIZE_TO_FEED
	feed_button.disabled = already_owned or deck_too_small
	if not already_owned:
		feed_button.relic_preview = FORGED_CONDUIT

	tribute_button.disabled = run_stats.gold < TRIBUTE_GOLD_COST or character_stats.deck.cards.is_empty()

	feed_button.event_button_callback = feed_card
	tribute_button.event_button_callback = pay_tribute
	leave_button.event_button_callback = skip


func feed_card() -> void:
	var picked: Card = RNG.array_pick_random(character_stats.deck.cards)
	character_stats.deck.cards.erase(picked)
	character_stats.deck.card_pile_size_changed.emit(character_stats.deck.cards.size())
	if relic_handler:
		relic_handler.add_relic(FORGED_CONDUIT)
	resolve("The anvil swallows %s in a hiss of steam. Gained Forged Conduit." % format_card_name(picked))


func pay_tribute() -> void:
	var picked: Card = RNG.array_pick_random(character_stats.deck.cards)
	var copy: Card = picked.duplicate()
	run_stats.gold -= TRIBUTE_GOLD_COST
	character_stats.deck.add_card(copy)
	resolve("Gold runs into the crucible. A copy of %s slides off the anvil, still warm." % format_card_name(copy))
