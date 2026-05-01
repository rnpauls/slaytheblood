class_name EquipmentCardRenderContainer
extends MarginContainer

signal pressed(equipment: Equipment)
signal tooltip_requested(icon: Texture, text: String)

@export var equipment: Equipment : set = set_equipment
@export var clickable: bool = true

@onready var equipment_ui: EquipmentUI = $Stack/EquipmentUI
@onready var button: Button = $Stack/Button

func _ready() -> void:
	if equipment:
		equipment_ui.equipment = equipment
	button.pressed.connect(_on_pressed)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.disabled = not clickable

func set_equipment(new_equipment: Equipment) -> void:
	equipment = new_equipment
	if is_node_ready() and equipment_ui:
		equipment_ui.equipment = equipment

func _on_pressed() -> void:
	if equipment:
		pressed.emit(equipment)

func _on_mouse_entered() -> void:
	if equipment:
		tooltip_requested.emit(equipment.icon, equipment.get_tooltip())

func _on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
