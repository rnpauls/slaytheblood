@tool
class_name InventoryCardRenderContainer
extends CenterContainer

const HOVER_TWEEN_TIME := 0.1
const CARD_ASPECT := 2.0 / 3.0
const NATURAL_SIZE := Vector2(200, 300)

signal equipment_pressed(equipment: Equipment)
signal pressed(item: Resource)

@export var weapon: Weapon : set = set_weapon
@export var equipment: Equipment : set = set_equipment
@export var clickable: bool = false : set = set_clickable

# base_scale and hover_scale are absolute fractions of NATURAL_SIZE — the
# hovered size is NOT a multiplier on top of base_scale.
@export_group("Scaling")
@export var base_scale: float = 1.0 : set = set_base_scale
@export var hover_scale: float = 1.1

@onready var sub_viewport_viewer: TextureRect = %SubViewportViewer
@onready var inventory_card: InventoryCard = $SubViewport/InventoryCard
@onready var sub_viewport: SubViewport = %SubViewport
@onready var button: Button = %Button
@onready var stack: Control = %Stack
@onready var glow_panel: Panel = %GlowPanel

var _hover_tween: Tween


func _ready() -> void:
	sub_viewport_viewer.texture = sub_viewport.get_texture()
	button.pressed.connect(_on_pressed)
	# Hover signals always fire (even when the button is disabled), so we can
	# show keyword tooltips on hover regardless of whether the container is
	# clickable for equip/unequip.
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	stack.resized.connect(_update_pivot)
	stack.resized.connect(_fit_glow_to_card)
	# CenterContainer.fit_child_in_rect resets stack.scale to (1, 1) every sort,
	# so re-apply on each sort to keep base_scale in effect (mirrors CardMenuUI).
	sort_children.connect(_apply_base_scale)
	_apply_base_scale()
	_fit_glow_to_card()
	_apply_clickable()


func _update_pivot() -> void:
	stack.pivot_offset = stack.size * 0.5


# Mirror SubViewportViewer's STRETCH_KEEP_ASPECT_CENTERED so the glow halo
# tracks the visible card edges instead of the full grid cell.
func _fit_glow_to_card() -> void:
	var s := stack.size
	if s.x <= 0 or s.y <= 0:
		return
	var inset := Vector2.ZERO
	if s.x / s.y > CARD_ASPECT:
		inset.x = (s.x - s.y * CARD_ASPECT) * 0.5
	else:
		inset.y = (s.y - s.x / CARD_ASPECT) * 0.5
	glow_panel.offset_left = inset.x
	glow_panel.offset_right = -inset.x
	glow_panel.offset_top = inset.y
	glow_panel.offset_bottom = -inset.y


func set_clickable(value: bool) -> void:
	clickable = value
	if not is_node_ready():
		return
	_apply_clickable()


func _apply_clickable() -> void:
	# Keep the button visible (it's flat=true so invisible visually) so its
	# mouse_entered/exited fire for the hover tooltip even when unclickable.
	# Disabling stops the press without removing the hit area.
	button.disabled = not clickable


func set_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	if not is_node_ready():
		await ready
	inventory_card.weapon = weapon


func set_equipment(new_equipment: Equipment) -> void:
	equipment = new_equipment
	if not is_node_ready():
		await ready
	inventory_card.equipment = equipment


func _on_pressed() -> void:
	if Engine.is_editor_hint():
		return
	if equipment:
		equipment_pressed.emit(equipment)
		pressed.emit(equipment)
	elif weapon:
		pressed.emit(weapon)


func _on_mouse_entered() -> void:
	if Engine.is_editor_hint():
		return
	_set_hovered(true)
	var tooltip_text := ""
	if weapon:
		tooltip_text = weapon.get_tooltip()
	elif equipment:
		tooltip_text = equipment.get_tooltip()
	if tooltip_text.is_empty():
		return
	var entries: Array[TooltipData] = KeywordRegistry.build_tooltip_chain(tooltip_text)
	if entries.is_empty():
		return
	Events.tooltip_show_requested.emit(entries, Rect2(global_position, size))


func _on_mouse_exited() -> void:
	if Engine.is_editor_hint():
		return
	_set_hovered(false)
	Events.tooltip_hide_requested.emit()


func _set_hovered(value: bool) -> void:
	glow_panel.visible = value
	# Lift above sibling cards so the scaled card overflows on top of neighbors.
	z_index = 10 if value else 0
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	# Stack's size is NATURAL * base_scale (driven by custom_minimum_size below),
	# so stack.scale here is a multiplier on top of that resting size. Resolve
	# the absolute hover/base targets back into a stack.scale ratio.
	if value:
		# Instant zoom in to hover_scale * NATURAL.
		stack.scale = Vector2.ONE * (hover_scale / base_scale)
	else:
		# Tween back to rest (stack.scale = ONE -> visual = NATURAL * base_scale).
		_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		_hover_tween.tween_property(stack, "scale", Vector2.ONE, HOVER_TWEEN_TIME)


func set_base_scale(value: float) -> void:
	base_scale = value
	if not is_node_ready():
		return
	_apply_base_scale()


# CenterContainer's C++ get_minimum_size() returns the max of children's
# combined minimum sizes (bypassing our GDScript _get_minimum_size override),
# so we drive the container's reported size via Stack.custom_minimum_size.
# Stack.size then equals NATURAL_SIZE * base_scale, and stack.scale stays at
# ONE at rest -- the visual size IS the stack size.
func _apply_base_scale() -> void:
	var rest_size := NATURAL_SIZE * base_scale
	stack.custom_minimum_size = rest_size
	stack.pivot_offset = rest_size / 2.0
	stack.scale = Vector2.ONE
	update_minimum_size()


# Kept as a defensive fallback; in practice CenterContainer's C++
# get_minimum_size overrides this, so the real driver is Stack.custom_minimum_size.
func _get_minimum_size() -> Vector2:
	return NATURAL_SIZE * base_scale
