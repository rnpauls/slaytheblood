## A short die-roll visual: a big number label that cycles through 1–6
## a few times before settling on the rolled value, then floats up and out.
## Used by scabskin_leathers (the active ability rolls a d6 for AP) and
## reusable for any future d6 mechanic.
class_name DiceRoll
extends Node2D

const CYCLE_INTERVAL := 0.05
const CYCLES := 8
const SETTLE_HOLD := 0.4
const RISE_PIXELS := 30.0

@onready var label: Label = $Label

var _final_value: int = 1

func setup(rolled_value: int) -> Node2D:
	_final_value = clampi(rolled_value, 1, 6)
	return self

func _ready() -> void:
	# Quick reel of random faces.
	var t := create_tween()
	for i in CYCLES:
		var face := randi_range(1, 6)
		t.tween_callback(func(): label.text = str(face))
		t.tween_interval(CYCLE_INTERVAL)
	# Settle on the real value.
	t.tween_callback(func(): label.text = str(_final_value))
	t.tween_interval(SETTLE_HOLD)
	# Float up + fade.
	t.parallel().tween_property(self, "position:y", position.y - RISE_PIXELS, SETTLE_HOLD) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(label, "modulate:a", 0.0, SETTLE_HOLD) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)
