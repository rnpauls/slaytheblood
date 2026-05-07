## Owns the tooltip stack for the whole scene. Listens on Events for show/hide
## requests, spawns one TooltipBox per TooltipData, lays them out in a vertical
## column anchored either to a source rect (right of the source, flips left if
## no room) or to the mouse, and clamps the whole stack to the viewport.
##
## Single-source-of-truth design: replaces the old `Tooltip` singleton and the
## scattered card_tooltip_requested / status_tooltip_requested signals.
##
## Lives once at run scope (under a CanvasLayer in run.tscn) so battle / shop /
## deck view / etc. all get tooltips for free via the Events signal bus. No
## class_name because the layer is unique and only addressed by signal.
##
## Inherits the show/hide/settle/position pipeline from PositionedPopupLayer.
extends PositionedPopupLayer

const TOOLTIP_BOX := preload("res://scenes/ui/tooltip_box.tscn")


func _connect_events() -> void:
	Events.tooltip_show_requested.connect(show_tooltips)
	Events.tooltip_hide_requested.connect(hide_now)


## entries: one TooltipData per box, top-to-bottom.
## anchor_rect: source rect in canvas coords. Pass Rect2() to anchor to mouse.
func show_tooltips(entries: Array[TooltipData], anchor_rect: Rect2 = Rect2()) -> void:
	if entries.is_empty():
		return
	_run_show(entries, anchor_rect)


func _build_content(payload: Variant) -> void:
	for entry: TooltipData in (payload as Array):
		if entry == null:
			continue
		var box := TOOLTIP_BOX.instantiate() as TooltipBox
		add_child(box)
		box.set_data(entry)
