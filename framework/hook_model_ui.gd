class_name HookModelUI
extends Control

## Displays a single visible AbstractModel in the status bar.
## Mirrors StatusUI but driven by AbstractModel instead of Status.
## The scene expects child nodes named Icon, Stacks (same layout as status_ui.tscn).

@onready var icon: TextureRect = $Icon
@onready var stacks: Label = $Stacks

var model: AbstractModel : set = set_model


func set_model(m: AbstractModel) -> void:
	if not is_node_ready():
		await ready

	model = m
	icon.texture = model.ui_icon()
	stacks.visible = model.ui_stack_text() != ""
	stacks.text = model.ui_stack_text()

	if not model.model_changed.is_connected(_on_model_changed):
		model.model_changed.connect(_on_model_changed)

	_on_model_changed()


func _on_model_changed() -> void:
	if not model:
		return
	stacks.text = model.ui_stack_text()
	stacks.visible = model.ui_stack_text() != ""
