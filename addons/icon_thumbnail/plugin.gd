@tool
extends EditorPlugin

const IconPreviewGenerator := preload("res://addons/icon_thumbnail/icon_preview_generator.gd")

var _generator: IconPreviewGenerator

func _enter_tree() -> void:
	_generator = IconPreviewGenerator.new()
	EditorInterface.get_resource_previewer().add_preview_generator(_generator)

func _exit_tree() -> void:
	if _generator:
		EditorInterface.get_resource_previewer().remove_preview_generator(_generator)
		_generator = null
