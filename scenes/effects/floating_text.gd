class_name FloatingText
extends Node2D

const RISE_PIXELS := 40.0
const LIFETIME := 0.7

@onready var label: Label = $Label

## Public setup — call right after instantiate, before adding to tree.
## `color` tints the label; `font_size` lets callers bump big hits.
##
## NOTE: Labels with `label_settings` ignore add_theme_color_override / font
## size overrides — label_settings always wins. So we duplicate the assigned
## LabelSettings per spawn and mutate the copy. Slight per-spawn allocation
## cost, but the alternative (mutating the shared resource) would change every
## label on screen.
func setup(text: String, color: Color, font_size: int = 28) -> void:
	if not is_node_ready():
		await ready
	label.text = text
	if label.label_settings:
		var ls: LabelSettings = label.label_settings.duplicate()
		ls.font_color = color
		ls.font_size = font_size
		label.label_settings = ls
	else:
		label.add_theme_color_override("font_color", color)
		label.add_theme_font_size_override("font_size", font_size)

func _ready() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position:y", position.y - RISE_PIXELS, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(queue_free)
