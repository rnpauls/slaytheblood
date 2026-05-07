## Owns the big InventoryCard hover preview plus its keyword chain. Listens on
## Events for show/hide requests, instantiates one InventoryCard for the
## hovered weapon/equipment, then stacks one TooltipBox below it per keyword
## referenced in the body. The whole column is positioned next to the source
## rect (left-of-source by default, flips right if no room — the opposite of
## TooltipLayer so card-in-hand tooltips and weapon/equipment previews settle
## on natural opposite sides when both could be on screen).
##
## Mirrors TooltipLayer's pattern (top_level, mouse_ignore, generation-gated
## delayed show, modulate fade, settle-then-show) but uses a longer hover_delay
## since the preview is bigger UI and should only commit once the user has
## clearly settled on the source.
extends VBoxContainer

const INVENTORY_CARD_SCENE := preload("res://scenes/inventory_card/inventory_card.tscn")
const TOOLTIP_BOX := preload("res://scenes/ui/tooltip_box.tscn")
const CARD_SIZE := Vector2(200, 300)

@export var fade_seconds := Constants.TWEEN_FADE
## Longer than TooltipLayer's 0.15s — the inventory preview is bigger UI and
## should only commit after the user has clearly settled on the source.
@export var hover_delay := 0.5
@export var screen_padding := 8.0
## Distance from anchor rect to nearest preview edge when source-anchored.
@export var source_offset := 8.0

var _is_preview_visible: bool = false
var _anchor_rect: Rect2 = Rect2()
var _tween: Tween
## Incremented on every show/hide so a delayed show can detect it was
## superseded (or cancelled) while it was waiting.
var _show_generation: int = 0


func _ready() -> void:
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.inventory_preview_show_requested.connect(show_preview)
	Events.inventory_preview_hide_requested.connect(hide_preview)
	modulate = Color.TRANSPARENT
	hide()


func _process(_delta: float) -> void:
	# Gate on modulate.a so we don't reposition during the pre-show settle phase
	# while the VBoxContainer is still laying out its children's true min size.
	if modulate.a > 0.0:
		_update_position()


## Exactly one of weapon/equipment should be set; the other is null.
## anchor_rect: source rect in canvas coords. Pass Rect2() to anchor to mouse.
func show_preview(weapon: Weapon, equipment: Equipment, anchor_rect: Rect2 = Rect2()) -> void:
	if weapon == null and equipment == null:
		return

	_show_generation += 1
	var gen := _show_generation

	if hover_delay > 0.0:
		await get_tree().create_timer(hover_delay, false).timeout
		if gen != _show_generation:
			return

	# Stay Godot-visible (so layout runs) but user-invisible during the swap —
	# RichTextLabels inside TooltipBox only finalize their wrap height once
	# they've been laid out at their actual rendered width.
	modulate = Color.TRANSPARENT
	show()
	# Reset our own size so a previous (likely larger) layout doesn't bias the
	# new children's first wrap calculation.
	size = Vector2.ZERO
	_is_preview_visible = true
	_anchor_rect = anchor_rect
	if _tween:
		_tween.kill()

	_clear_children()

	var card := INVENTORY_CARD_SCENE.instantiate() as InventoryCard
	# The inventory card scene defaults to full-rect anchors (assumes a
	# containing layout slot). Inside a VBoxContainer we want it sized by its
	# custom_minimum_size, so reset the anchors and let the container drive it.
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE, 0)
	card.custom_minimum_size = CARD_SIZE
	add_child(card)
	if weapon:
		card.weapon = weapon
	elif equipment:
		card.equipment = equipment

	var tooltip_text := weapon.get_tooltip() if weapon else equipment.get_tooltip()
	for entry: TooltipData in KeywordRegistry.build_tooltip_chain(tooltip_text):
		var box := TOOLTIP_BOX.instantiate() as TooltipBox
		add_child(box)
		box.set_data(entry)

	# Wait until get_combined_minimum_size() stabilizes — same settle pattern
	# as TooltipLayer. Two or three frames is typically enough.
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


func hide_preview() -> void:
	_is_preview_visible = false
	# Cancel any in-flight delayed show so it doesn't pop up after the hide.
	_show_generation += 1
	if _tween:
		_tween.kill()
	# Debounce: if a new show comes in during fade-out, _is_preview_visible
	# will be true again by the time the timer fires and we'll skip the hide.
	get_tree().create_timer(fade_seconds, false).timeout.connect(_hide_animation)


func _hide_animation() -> void:
	if _is_preview_visible:
		return
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
	_tween.tween_callback(_after_hide)


func _after_hide() -> void:
	hide()
	_clear_children()


func _clear_children() -> void:
	# Synchronous removal so the next add_child sees an empty tree. queue_free
	# alone is deferred, leaving stale children for the rest of the frame —
	# VBoxContainer's layout would then aggregate old + new and inflate `size`.
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _update_position() -> void:
	var viewport_rect := get_viewport_rect()
	# Read from min-size aggregation rather than the `size` property — `size`
	# lags by one layout pass after children change.
	var stack_size := get_combined_minimum_size()
	var desired: Vector2

	if _anchor_rect.has_area():
		# Default: left-of-source (mirror of TooltipLayer's right-of-source) so
		# the big preview and any card-in-hand keyword tooltips naturally take
		# opposite sides of a hovered source.
		desired = Vector2(
			_anchor_rect.position.x - stack_size.x - source_offset,
			_anchor_rect.position.y
		)
		# Flip to the right if no room on the left.
		if desired.x < screen_padding:
			desired.x = _anchor_rect.position.x + _anchor_rect.size.x + source_offset
	else:
		var mouse_pos := get_global_mouse_position()
		desired = mouse_pos + Vector2(16, 16)

	# Clamp to viewport. Skip clamp on either axis when the bounds invert
	# (stack briefly larger than viewport while RichTextLabels are still
	# settling their wrap height).
	var max_x := viewport_rect.size.x - stack_size.x - screen_padding
	var max_y := viewport_rect.size.y - stack_size.y - screen_padding
	if max_x >= screen_padding:
		desired.x = clamp(desired.x, screen_padding, max_x)
	if max_y >= screen_padding:
		desired.y = clamp(desired.y, screen_padding, max_y)

	global_position = desired
