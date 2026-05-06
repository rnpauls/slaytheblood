class_name InventoryCardRenderContainer
extends MarginContainer

signal equipment_pressed(equipment: Equipment)
signal pressed(item: Resource)

@export var weapon: Weapon : set = set_weapon
@export var equipment: Equipment : set = set_equipment
@export var clickable: bool = false : set = set_clickable

@onready var sub_viewport_viewer: TextureRect = %SubViewportViewer
@onready var inventory_card: InventoryCard = $SubViewport/InventoryCard
@onready var sub_viewport: SubViewport = %SubViewport
@onready var button: Button = %Button


func _ready() -> void:
	sub_viewport_viewer.texture = sub_viewport.get_texture()
	button.pressed.connect(_on_pressed)
	# Hover signals always fire (even when the button is disabled), so we can
	# show keyword tooltips on hover regardless of whether the container is
	# clickable for equip/unequip.
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	_apply_clickable()


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
	Events.tooltip_hide_requested.emit()
