class_name HealthBar
extends ProgressBar

@onready var label: Label = %HealthLabel

func update_stats(stats: Stats) -> void:
	max_value = stats.max_health
	value = stats.health
	label.text = "%d/%d" % [stats.health, stats.max_health]
