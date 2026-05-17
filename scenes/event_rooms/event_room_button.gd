class_name EventRoomButton
extends Button

var event_button_callback: Callable

## When set, the button shows a hover tooltip previewing this relic so the
## player can see what they're committing to before clicking. Mirrors the
## RelicUI hover tooltip.
var relic_preview: Relic : set = set_relic_preview


func _on_pressed() -> void:
	if event_button_callback:
		event_button_callback.call()


func set_relic_preview(value: Relic) -> void:
	relic_preview = value
	if relic_preview:
		TooltipHelper.attach(self, relic_preview.relic_name, relic_preview.get_tooltip(), relic_preview.icon)
