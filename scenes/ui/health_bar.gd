class_name HealthBar
extends ProgressBar

# STS-style trail: on damage, the red fill drops instantly and a yellow strip
# is shown spanning the lost range; the strip shrinks back toward the new
# value over TRAIL_DURATION so the player can read the magnitude of the hit.
const TRAIL_DURATION := 0.4

@onready var label: Label = %HealthLabel
@onready var trail_fill: ColorRect = $TrailFill

# Tracks the displayed value across updates so we can compute the damage
# delta on each stats_changed. -1 = first update, no trail.
var _prev_value: float = -1.0
var _trail_tween: Tween

func update_stats(stats: Stats) -> void:
	var old_val := _prev_value if _prev_value >= 0 else float(stats.health)
	max_value = stats.max_health
	value = stats.health
	label.text = "%d/%d" % [stats.health, stats.max_health]
	var new_val := float(stats.health)
	if _prev_value >= 0 and new_val < old_val and max_value > 0:
		_show_damage_trail(old_val, new_val)
	_prev_value = new_val


# Yellow strip from new health position to old health position; shrinks its
# width to 0 over TRAIL_DURATION so it reads as the lost chunk receding into
# the current value.
func _show_damage_trail(old_val: float, new_val: float) -> void:
	if not trail_fill or size.x <= 0.0:
		return
	var bar_width := size.x
	var new_x := (new_val / max_value) * bar_width
	var old_x := (old_val / max_value) * bar_width
	trail_fill.position = Vector2(new_x, 0.0)
	trail_fill.size = Vector2(maxf(old_x - new_x, 0.0), size.y)
	trail_fill.color = Palette.GOLD_HIGHLIGHT
	trail_fill.show()
	if _trail_tween and _trail_tween.is_running():
		_trail_tween.kill()
	_trail_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_trail_tween.tween_property(trail_fill, "size:x", 0.0, TRAIL_DURATION)
	_trail_tween.tween_callback(trail_fill.hide)
