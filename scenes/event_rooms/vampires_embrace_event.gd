extends EventRoom

const CRIMSON_FANG := preload("res://relics/crimson_fang.tres")
const BITE_MAX_HP_COST := 8
const REFUSE_HP_COST := 5
const REFUSE_GOLD_GAIN := 60

@onready var accept_button: EventRoomButton = %AcceptButton
@onready var refuse_button: EventRoomButton = %RefuseButton
@onready var leave_button: EventRoomButton = %LeaveButton


func setup() -> void:
	super.setup()

	var already_owned := relic_handler and relic_handler.has_relic(CRIMSON_FANG.id)
	accept_button.disabled = character_stats.max_health <= BITE_MAX_HP_COST or already_owned
	if not already_owned:
		accept_button.relic_preview = CRIMSON_FANG

	refuse_button.disabled = character_stats.health <= REFUSE_HP_COST

	accept_button.event_button_callback = accept_bite
	refuse_button.event_button_callback = refuse_gift
	leave_button.event_button_callback = skip


func accept_bite() -> void:
	character_stats.max_health -= BITE_MAX_HP_COST
	if relic_handler:
		relic_handler.add_relic(CRIMSON_FANG)
	resolve("Her fangs drink deep. You feel the hunger settle in your veins. Gained Crimson Fang.")


func refuse_gift() -> void:
	character_stats.set_health(character_stats.health - REFUSE_HP_COST)
	run_stats.gold += REFUSE_GOLD_GAIN
	resolve("You ward her off, bloodied but free. You loot her purse: +%d gold." % REFUSE_GOLD_GAIN)
