class_name InventoryCardRenderContainer
extends MarginContainer

const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_TWEEN_TIME := 0.1

signal equipment_pressed(equipment: Equipment)
signal pressed(item: Resource)

@export var weapon: Weapon : set = set_weapon
@export var equipment: Equipment : set = set_equipment
@export var clickable: bool = false : set = set_clickable

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
	_update_pivot()
	_apply_clickable()


func _update_pivot() -> void:
	stack.pivot_offset = stack.size * 0.5


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
	if equipment:
		equipment_pressed.emit(equipment)
		pressed.emit(equipment)
	elif weapon:
		pressed.emit(weapon)


func _on_mouse_entered() -> void:
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
	_set_hovered(false)
	Events.tooltip_hide_requested.emit()


func _set_hovered(value: bool) -> void:
	glow_panel.visible = value
	# Lift above sibling cards so the scaled card overflows on top of neighbors.
	z_index = 10 if value else 0
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(stack, "scale", HOVER_SCALE if value else Vector2.ONE, HOVER_TWEEN_TIME)
