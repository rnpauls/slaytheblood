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
extends VBoxContainer

const TOOLTIP_BOX := preload("res://scenes/ui/tooltip_box.tscn")

@export var fade_seconds := Constants.TWEEN_FADE
## Filter out brief hovers — flicking the mouse across the hand shouldn't
## strobe tooltips. Set to 0 to show immediately.
@export var hover_delay := 0.15
@export var mouse_offset := Vector2(16, 16)
@export var screen_padding := 8.0
## Distance from anchor rect to nearest tooltip edge when source-anchored.
@export var source_offset := 8.0

var _is_tooltip_visible: bool = false
var _anchor_rect: Rect2 = Rect2()
var _tween: Tween
## Incremented on every show/hide so a delayed show can detect it was
## superseded (or cancelled) while it was waiting.
var _show_generation: int = 0


func _ready() -> void:
	# Drive position in screen space; ignore parent layout.
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.tooltip_show_requested.connect(show_tooltips)
	Events.tooltip_hide_requested.connect(hide_tooltips)
	modulate = Color.TRANSPARENT
	hide()


func _process(_delta: float) -> void:
	# Gate on modulate.a, not `visible`: while we're swapping content we keep
	# the node `visible` so Godot runs its layout pass (RichTextLabel needs the
	# layout to know its rendered width before it can report a final wrap
	# height), but modulate.a is 0 so the user can't see the work in progress.
	if modulate.a > 0.0:
		_update_position()


## entries: one TooltipData per box, top-to-bottom.
## anchor_rect: source rect in canvas coords. Pass Rect2() to anchor to mouse.
func show_tooltips(entries: Array[TooltipData], anchor_rect: Rect2 = Rect2()) -> void:
	if entries.is_empty():
		return

	_show_generation += 1
	var gen := _show_generation

	if hover_delay > 0.0:
		await get_tree().create_timer(hover_delay, false).timeout
		# Bail if a hide came in or another show superseded us.
		if gen != _show_generation:
			return

	# Stay Godot-visible (layout runs) but user-invisible (modulate transparent)
	# during the swap. Going visible=false here would freeze the layout cascade
	# — RichTextLabel only finalizes its wrap height once it has been laid out
	# at its real rendered width, and that pass is skipped while the node is
	# hidden. _process is gated on modulate.a so it won't reposition during
	# this phase.
	modulate = Color.TRANSPARENT
	show()
	# Reset our own size so a previous (likely larger) layout doesn't bias
	# the new RichTextLabels' first wrap calculation.
	size = Vector2.ZERO
	_is_tooltip_visible = true
	_anchor_rect = anchor_rect
	if _tween:
		_tween.kill()

	_clear_boxes()
	for entry: TooltipData in entries:
		if entry == null:
			continue
		var box := TOOLTIP_BOX.instantiate() as TooltipBox
		add_child(box)
		box.set_data(entry)

	# Wait until get_combined_minimum_size() stabilizes. The PanelContainer →
	# VBox → RichTextLabel cascade typically settles in 2–3 frames once the
	# layer is visible: first frame fires _ready and lets set_data populate
	# the labels; subsequent frames let RTL re-wrap at the actual rendered
	# width and report the final min size.
	var prev_min := Vector2(-1, -1)
	var current_min := get_combined_minimum_size()
	var settle_attempts := 6
	while prev_min != current_min and settle_attempts > 0:
		await get_tree().process_frame
		if gen != _show_generation:
			return
		prev_min = current_min
		current_min = get_combined_minimum_size()
		settle_attempts -= 1

	_update_position()

	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)


func hide_tooltips() -> void:
	_is_tooltip_visible = false
	# Cancel any in-flight delayed show so it doesn't pop up after the hide.
	_show_generation += 1
	if _tween:
		_tween.kill()
	# Debounce: if a new show comes in during fade-out, _is_tooltip_visible
	# will be true again by the time the timer fires and we'll skip the hide.
	get_tree().create_timer(fade_seconds, false).timeout.connect(_hide_animation)


func _hide_animation() -> void:
	if _is_tooltip_visible:
		return
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
	_tween.tween_callback(_after_hide)


func _after_hide() -> void:
	hide()
	_clear_boxes()


func _clear_boxes() -> void:
	# Remove synchronously so the next add_child sees an empty tree. queue_free
	# alone is deferred, leaving stale children in the tree for the rest of the
	# frame — VBoxContainer's layout would then see old + new together and the
	# inflated `size` would propagate into _update_position's clamp, walking the
	# tooltip upward across rapid hovers.
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _update_position() -> void:
	var viewport_rect := get_viewport_rect()
	# Read size from min-size aggregation rather than the `size` property.
	# `size` lags by one layout pass after children change, which is the wrong
	# basis for clamping just after add_child / remove_child.
	var stack_size := get_combined_minimum_size()
	var desired: Vector2

	if _anchor_rect.has_area():
		# Default: top-of-stack aligned to top-of-source, on the right side.
		desired = Vector2(
			_anchor_rect.position.x + _anchor_rect.size.x + source_offset,
			_anchor_rect.position.y
		)
		# Horizontal flip if no room to the right.
		if desired.x + stack_size.x + screen_padding > viewport_rect.size.x:
			desired.x = _anchor_rect.position.x - stack_size.x - source_offset
		# No vertical flip — the final clamp below pins the stack to the
		# viewport's bottom edge if it would otherwise overflow. Flipping
		# bottom-to-bottom against partially-laid-out children produced a
		# one-frame flash to screen top before set_data populated the labels.
	else:
		# Mouse-anchored fallback for sources that don't pass a rect.
		var mouse_pos := get_global_mouse_position()
		desired = mouse_pos + mouse_offset
		if desired.x + stack_size.x + screen_padding > viewport_rect.size.x:
			desired.x = mouse_pos.x - stack_size.x - mouse_offset.x
		if desired.y + stack_size.y + screen_padding > viewport_rect.size.y:
			desired.y = mouse_pos.y - stack_size.y - mouse_offset.y

	# Final clamp covers cases where flipping still isn't enough (tiny viewport,
	# very tall stack). Skip the clamp on either axis when the bounds invert
	# (stack briefly larger than viewport while bbcode RichTextLabels are still
	# settling their wrap height) — otherwise clamp returns the negative max and
	# slams the tooltip toward the top-left for one frame.
	var max_x := viewport_rect.size.x - stack_size.x - screen_padding
	var max_y := viewport_rect.size.y - stack_size.y - screen_padding
	if max_x >= screen_padding:
		desired.x = clamp(desired.x, screen_padding, max_x)
	if max_y >= screen_padding:
		desired.y = clamp(desired.y, screen_padding, max_y)

	global_position = desired
