## Base class for stacked, source-anchored popup layers (TooltipLayer,
## InventoryPreviewLayer). Owns the show/hide/settle/position pipeline:
## generation-gated delayed show, modulate-fade, multi-frame settle so
## RichTextLabel wrap heights stabilize before the layer becomes visible,
## anchor-rect positioning with viewport flip+clamp, mouse-anchored fallback.
##
## Subclasses provide:
##   _connect_events()    — wire their Events signals; call _run_show(payload, rect)
##                          and hide_now() in their handlers.
##   _build_content(p)    — populate children for a given payload (typed in
##                          subclass; payload Variant in the base contract).
##
## Ownership rules subclasses must respect:
##   * Don't keep references to children — _clear_children() will free them
##     synchronously on the next show.
##   * Don't override _process; the base gates positioning on modulate.a.
##   * Don't change `top_level` or `mouse_filter` after _ready.
class_name PositionedPopupLayer
extends VBoxContainer

@export var fade_seconds := Constants.TWEEN_FADE
## Filter out brief hovers — flicking the mouse across UI shouldn't strobe the
## popup. 0 to show immediately. Subclasses tune this; tooltips are short
## (0.15), the bigger inventory preview is longer (0.5).
@export var hover_delay := 0.15
@export var screen_padding := 8.0
## Distance from anchor rect to nearest popup edge when source-anchored.
@export var source_offset := 8.0
## Default side for source-anchored placement. False (TooltipLayer): right of
## source, flips left if no room. True (InventoryPreviewLayer): left of source,
## flips right.
@export var prefer_left_of_source := false
## Offset from mouse pointer in mouse-anchored fallback mode.
@export var mouse_offset := Vector2(16, 16)

var _is_visible: bool = false
var _anchor_rect: Rect2 = Rect2()
var _tween: Tween
## Incremented on every show/hide so a delayed show can detect it was
## superseded (or cancelled) while it was waiting.
var _show_generation: int = 0
## When true, a hide_now() request is queued and waiting for end-of-frame
## resolution. _run_show clears this so a same-frame show beats the hide.
var _pending_hide: bool = false
## Frame number when _run_show was last called. A hide_now() called in the
## same frame bails — show always wins over hide in a same-frame transition,
## regardless of which signal fired first (Godot's mouse_exited /
## mouse_entered dispatch order is not guaranteed when moving between an
## Area2D and a Control).
var _show_called_frame: int = -1


func _ready() -> void:
	# Drive position in screen space; ignore parent layout.
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.TRANSPARENT
	hide()
	_connect_events()


func _process(_delta: float) -> void:
	# Gate on modulate.a, not `visible`: while we're swapping content we keep
	# the node `visible` so Godot runs its layout pass (RichTextLabel needs the
	# layout to know its rendered width before it can report a final wrap
	# height), but modulate.a is 0 so the user can't see the work in progress.
	if modulate.a > 0.0:
		_update_position()


# ── Subclass extension points ────────────────────────────────────────────────

## Override to wire Events signals to subclass show/hide methods.
func _connect_events() -> void:
	pass

## Override to populate children for the given payload.
## Called inside _run_show after _clear_children and before the settle loop.
func _build_content(_payload: Variant) -> void:
	pass


# ── Shared show / hide pipeline ──────────────────────────────────────────────

## Subclass calls this from its own show method. Returns nothing; runs the
## delayed-show + settle + fade-in sequence.
func _run_show(payload: Variant, anchor_rect: Rect2) -> void:
	# A show in the same frame overrides any queued hide. Stamp the frame so a
	# hide_now() called after this can detect "same-frame" and bail.
	_pending_hide = false
	_show_called_frame = Engine.get_process_frames()
	_show_generation += 1
	var gen := _show_generation

	if hover_delay > 0.0:
		await get_tree().create_timer(hover_delay, false).timeout
		# Bail if a hide came in or another show superseded us.
		if gen != _show_generation:
			return

	# Stay Godot-visible (layout runs) but user-invisible (modulate transparent)
	# during the swap. visible=false here would freeze the layout cascade —
	# RichTextLabel only finalizes its wrap height once it's been laid out at
	# its real rendered width, and that pass is skipped while hidden. _process
	# is gated on modulate.a so it won't reposition during this phase.
	modulate = Color.TRANSPARENT
	show()
	# Reset our own size so a previous (likely larger) layout doesn't bias the
	# new children's first wrap calculation.
	size = Vector2.ZERO
	_is_visible = true
	_anchor_rect = anchor_rect
	if _tween:
		_tween.kill()

	_clear_children()
	_build_content(payload)

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


## Subclass calls this from its own hide method.
func hide_now() -> void:
	# Defer the actual hide so a same-frame show can override it. Without this,
	# mouse transitions between two tooltipped sources (intent UI → enemy
	# sprite, etc.) race: whichever fires second wins, and the show often loses
	# because hide_now() also bumps _show_generation, which kills the pending
	# delayed show.
	#
	# Two same-frame orderings to consider:
	#   1. hide → show: _pending_hide is set, then show clears it. Resolve no-ops.
	#   2. show → hide: _show_called_frame matches current frame, this returns.
	if _show_called_frame == Engine.get_process_frames():
		return
	if _pending_hide:
		return
	_pending_hide = true
	call_deferred("_resolve_pending_hide")


func _resolve_pending_hide() -> void:
	if not _pending_hide:
		return  # A show came in this frame and cancelled us.
	_pending_hide = false
	_is_visible = false
	# Cancel any in-flight delayed show so it doesn't pop up after the hide.
	_show_generation += 1
	if _tween:
		_tween.kill()
	# Debounce: if a new show comes in during fade-out, _is_visible will be
	# true again by the time the timer fires and we'll skip the hide.
	get_tree().create_timer(fade_seconds, false).timeout.connect(_hide_animation)


func _hide_animation() -> void:
	if _is_visible:
		return
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
	_tween.tween_callback(_after_hide)


func _after_hide() -> void:
	hide()
	_clear_children()


func _clear_children() -> void:
	# Remove synchronously so the next add_child sees an empty tree. queue_free
	# alone is deferred, leaving stale children in the tree for the rest of the
	# frame — VBoxContainer's layout would then see old + new together and the
	# inflated `size` would propagate into _update_position's clamp.
	for child in get_children():
		remove_child(child)
		child.queue_free()


# ── Positioning ──────────────────────────────────────────────────────────────

func _update_position() -> void:
	var viewport_rect := get_viewport_rect()
	# Read size from min-size aggregation rather than the `size` property.
	# `size` lags by one layout pass after children change, which is the wrong
	# basis for clamping just after add_child / remove_child.
	var stack_size := get_combined_minimum_size()
	var desired: Vector2

	if _anchor_rect.has_area():
		if prefer_left_of_source:
			# Default: left-of-source. Flip right if no room on the left.
			desired = Vector2(
				_anchor_rect.position.x - stack_size.x - source_offset,
				_anchor_rect.position.y
			)
			if desired.x < screen_padding:
				desired.x = _anchor_rect.position.x + _anchor_rect.size.x + source_offset
		else:
			# Default: right-of-source. Flip left if no room on the right.
			desired = Vector2(
				_anchor_rect.position.x + _anchor_rect.size.x + source_offset,
				_anchor_rect.position.y
			)
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
	# slams the popup toward the top-left for one frame.
	var max_x := viewport_rect.size.x - stack_size.x - screen_padding
	var max_y := viewport_rect.size.y - stack_size.y - screen_padding
	if max_x >= screen_padding:
		desired.x = clamp(desired.x, screen_padding, max_x)
	if max_y >= screen_padding:
		desired.y = clamp(desired.y, screen_padding, max_y)

	global_position = desired
