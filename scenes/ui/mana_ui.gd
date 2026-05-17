class_name ManaUI
extends Panel

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var mana_label: Label = $ManaLabel

# Tracks the displayed mana so we can detect a GAIN delta and pop an azure
# burst on the panel. -1 = first update, no burst.
var _prev_mana: int = -1

func _ready() -> void:
	TooltipHelper.attach(self, "Mana", "Spent to play cards. Refills at the start of each turn.")


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value

	if not char_stats.stats_changed.is_connected(_on_stats_changed):
		char_stats.stats_changed.connect(_on_stats_changed)

	if not is_node_ready():
		await ready

	_on_stats_changed()

func _on_stats_changed() -> void:
	mana_label.text = "%s" % [char_stats.mana]
	if _prev_mana >= 0 and char_stats.mana > _prev_mana:
		FloatingTextSpawner.spawn_burst_at(self, size / 2.0, Palette.MANA_AZURE)
	_prev_mana = char_stats.mana
