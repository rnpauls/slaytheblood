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

## Instance id of the source that triggered the currently shown/pending tooltip.
## 0 means "no tracked owner" — un-owned show/hide work as before. Set by
## owner-tagged shows; cleared by any hide or by an un-owned show.
var _current_owner_id: int = 0


func _connect_events() -> void:
	Events.tooltip_show_requested.connect(show_tooltips)
	Events.tooltip_hide_requested.connect(_hide_unconditional)
	Events.tooltip_show_for_owner.connect(_show_for_owner)
	Events.tooltip_hide_for_owner.connect(_hide_for_owner)


## entries: one TooltipData per box, top-to-bottom.
## anchor_rect: source rect in canvas coords. Pass Rect2() to anchor to mouse.
func show_tooltips(entries: Array[TooltipData], anchor_rect: Rect2 = Rect2()) -> void:
	_current_owner_id = 0
	if entries.is_empty():
		return
	_run_show(entries, anchor_rect)


func _hide_unconditional() -> void:
	_current_owner_id = 0
	hide_now()


## Owner-tagged show: subsequent hides from sources with a different owner_id
## are ignored, which prevents a cross-frame hide from killing this show
## during its hover_delay phase.
func _show_for_owner(entries: Array[TooltipData], anchor_rect: Rect2, owner_id: int) -> void:
	_current_owner_id = owner_id
	if entries.is_empty():
		return
	_run_show(entries, anchor_rect)


func _hide_for_owner(owner_id: int) -> void:
	# Mismatch means the cursor already moved to a different owned source whose
	# show has taken over; ignore this stale hide.
	if owner_id != _current_owner_id:
		return
	_current_owner_id = 0
	hide_now()


func _build_content(payload: Variant) -> void:
	for entry: TooltipData in (payload as Array):
		if entry == null:
			continue
		var box := TOOLTIP_BOX.instantiate() as TooltipBox
		add_child(box)
		box.set_data(entry)
