class_name HealthUI
extends HBoxContainer

@export var show_max_hp: bool

@onready var health_label: Label = %HealthLabel
@onready var max_health_label: Label = %MaxHealthLabel


func _ready() -> void:
	TooltipHelper.attach(self, "Health", "Your hit points. At 0 your run ends.")


func update_stats(stats: Stats) -> void:
	health_label.text = str(stats.health)
	max_health_label.text = "/%s" % str(stats.max_health)
	max_health_label.visible = show_max_hp
