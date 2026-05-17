class_name ActionPointsUI
extends Panel

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var action_points_label: Label = $ActionPointsLabel

# Tracks the displayed AP so we can detect a GAIN delta and pop a gold burst
# on the panel. -1 = first update, no burst.
var _prev_ap: int = -1

func _ready() -> void:
	TooltipHelper.attach(self, "Action Points", "Spent to use weapons and equipment. Refills at the start of each turn.")


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value

	if not char_stats.stats_changed.is_connected(_on_stats_changed):
		char_stats.stats_changed.connect(_on_stats_changed)

	if not is_node_ready():
		await ready

	_on_stats_changed()

func _on_stats_changed() -> void:
	action_points_label.text = "%s" % [char_stats.action_points]
	if _prev_ap >= 0 and char_stats.action_points > _prev_ap:
		FloatingTextSpawner.spawn_burst_at(self, size / 2.0, Palette.GOLD_HIGHLIGHT)
	_prev_ap = char_stats.action_points
