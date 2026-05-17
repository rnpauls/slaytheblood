## Installs the custom cursor textures and auto-applies the
## CURSOR_POINTING_HAND shape to every BaseButton in the tree (existing and
## future). Pattern mirrors SFXRegistry's auto-attach so individual scenes
## don't have to remember to set mouse_default_cursor_shape.
extends Node

# Use the imported CompressedTexture2D from disk; Godot's
# Input.set_custom_mouse_cursor handles Texture2D natively. (An earlier
# version tried Image.load_from_file but that warns "will not work on
# export" — load() goes through the proper import pipeline.)
const ARROW := preload("res://art/ui/cursor/arrow.png")
const POINTER := preload("res://art/ui/cursor/pointer.png")
# Hotspots are guesses based on the asset silhouettes — tune in-editor.
const ARROW_HOTSPOT := Vector2(4, 4)
const POINTER_HOTSPOT := Vector2(8, 6)

func _ready() -> void:
	Input.set_custom_mouse_cursor(ARROW, Input.CURSOR_ARROW, ARROW_HOTSPOT)
	Input.set_custom_mouse_cursor(POINTER, Input.CURSOR_POINTING_HAND, POINTER_HOTSPOT)
	get_tree().node_added.connect(_on_node_added)
	_wire_subtree(get_tree().root)

func _wire_subtree(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_wire_subtree(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
