extends EventRoom

const WIN_BACKGROUND := preload("res://art/backgrounds/win.jpeg")

@onready var fifty_button: EventRoomButton = %FiftyButton
@onready var thirty_button: EventRoomButton = %ThirtyButton
@onready var skip_button: EventRoomButton = %SkipButton


func setup() -> void:
	super.setup()
	skip_button.visible = run_stats.gold < 50
	fifty_button.disabled = run_stats.gold < 50
	thirty_button.disabled = run_stats.gold < 50

	fifty_button.event_button_callback = bet_50
	thirty_button.event_button_callback = bet_30
	skip_button.event_button_callback = skip


func bet_30() -> void:
	run_stats.gold -= 50
	if RNG.instance.randf() < 0.3:
		run_stats.gold += 200
		resolve("Jackpot! You won 200 gold (net +150).", WIN_BACKGROUND)
	else:
		resolve("The reels stop short. You lost 50 gold.")


func bet_50() -> void:
	run_stats.gold -= 50
	if RNG.instance.randf() < 0.5:
		run_stats.gold += 100
		resolve("You won 100 gold (net +50).", WIN_BACKGROUND)
	else:
		resolve("The reels stop short. You lost 50 gold.")
