extends EventRoom

const MIRROR_SHARD := preload("res://relics/mirror_shard.tres")
const STEP_HP_COST := 8
const SMASH_GOLD_GAIN := 75
const MIN_DECK_SIZE_TO_STEP := 6

@onready var step_button: EventRoomButton = %StepButton
@onready var smash_button: EventRoomButton = %SmashButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()

	var already_owned := relic_handler and relic_handler.has_relic(MIRROR_SHARD.id)
	var deck_too_small := character_stats.deck.cards.size() < MIN_DECK_SIZE_TO_STEP
	var hp_too_low := character_stats.health <= STEP_HP_COST
	step_button.disabled = already_owned or deck_too_small or hp_too_low
	if not already_owned:
		step_button.relic_preview = MIRROR_SHARD

	step_button.event_button_callback = step_through
	smash_button.event_button_callback = smash_mirror
	leave_button.event_button_callback = skip


func step_through() -> void:
	character_stats.set_health(character_stats.health - STEP_HP_COST)
	var picked: Card = RNG.array_pick_random(character_stats.deck.cards)
	character_stats.deck.cards.erase(picked)
	character_stats.deck.card_pile_size_changed.emit(character_stats.deck.cards.size())
	if relic_handler:
		relic_handler.add_relic(MIRROR_SHARD)
	resolve("You pass through the glass. %s is lost to the other side. Gained Mirror Shard." % format_card_name(picked))


func smash_mirror() -> void:
	run_stats.gold += SMASH_GOLD_GAIN
	resolve("Shards rain down. You collect %d gold worth of jagged glass." % SMASH_GOLD_GAIN)
