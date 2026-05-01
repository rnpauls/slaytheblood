class_name HookStatusDisplay
extends GridContainer

## Watches Hook.model_registered / model_unregistered and shows an icon
## for every AbstractModel whose visible_in_ui() returns true.
##
## Usage: add a HookStatusDisplay node as a sibling of StatusHandler on
## each combatant. Set owner_node to the combatant Node so only that
## combatant's models are shown.
##
## Scene requirement: needs a preloaded HOOK_MODEL_UI scene with the same
## layout as status_ui.tscn (Icon: TextureRect, Stacks: Label).

const HOOK_MODEL_UI = preload("res://framework/hook_model_ui.tscn")

## Only display models owned by this node. Leave null to show all models.
@export var owner_node: Node2D


func _ready() -> void:
	Hook.model_registered.connect(_on_model_registered)
	Hook.model_unregistered.connect(_on_model_unregistered)


func _on_model_registered(model: AbstractModel) -> void:
	if not model.visible_in_ui():
		return
	if owner_node and model.owner() != owner_node:
		return

	var ui := HOOK_MODEL_UI.instantiate() as HookModelUI
	add_child(ui)
	ui.model = model


func _on_model_unregistered(model: AbstractModel) -> void:
	for child in get_children():
		var ui := child as HookModelUI
		if ui and ui.model == model:
			ui.queue_free()
			return


func _exit_tree() -> void:
	if Hook.model_registered.is_connected(_on_model_registered):
		Hook.model_registered.disconnect(_on_model_registered)
	if Hook.model_unregistered.is_connected(_on_model_unregistered):
		Hook.model_unregistered.disconnect(_on_model_unregistered)
