## "+X" shield popup spawned when an enemy resolves a block card.
## Self-cleaning: queue_frees after pop+hold+fade completes.
class_name BlockBadge
extends HBoxContainer

const HOLD_DURATION := 0.5

@onready var label: Label = $Label

func pop(amount: int) -> void:
	if not is_node_ready():
		await ready
	label.text = "+%d" % amount
	scale = Vector2.ZERO
	modulate.a = 0.0
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, Constants.TWEEN_BADGE_POP)
	t.parallel().tween_property(self, "modulate:a", 1.0, Constants.TWEEN_BADGE_POP)
	t.tween_interval(HOLD_DURATION)
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, Constants.TWEEN_FADE)
	t.tween_callback(queue_free)
