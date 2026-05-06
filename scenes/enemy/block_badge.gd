## "+X" shield popup spawned when an enemy resolves a block card.
## Self-cleaning: queue_frees after pop+hold+fade completes.
class_name BlockBadge
extends HBoxContainer

const POP_DURATION := 0.18
const HOLD_DURATION := 0.5
const FADE_DURATION := 0.25

@onready var label: Label = $Label

func pop(amount: int) -> void:
	if not is_node_ready():
		await ready
	label.text = "+%d" % amount
	scale = Vector2.ZERO
	modulate.a = 0.0
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, POP_DURATION)
	t.parallel().tween_property(self, "modulate:a", 1.0, POP_DURATION)
	t.tween_interval(HOLD_DURATION)
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	t.tween_callback(queue_free)
