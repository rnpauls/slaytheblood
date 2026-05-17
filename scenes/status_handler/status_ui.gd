class_name StatusUI
extends Control

# Hourglass glyph distinguishes duration-typed status badges (counts down
# every turn) from intensity-typed ones (stacks consumed by triggers). The
# asset is generated via pixellab and lazy-loaded; until it lands the
# TextureRect stays empty and the layout reads as before.
const HOURGLASS_ICON_PATH := "res://art/ui/hourglass.png"

@export var status: Status : set = set_status

@onready var icon: TextureRect = $Icon
@onready var duration: Label = $Duration
@onready var stacks: Label = $Stacks
@onready var hourglass: TextureRect = $Hourglass

func set_status(new_status: Status) -> void:
	if not is_node_ready():
		await ready

	status = new_status
	icon.texture = status.icon
	duration.visible = status.stack_type == Status.StackType.DURATION
	stacks.visible = status.stack_type == Status.StackType.INTENSITY
	if duration.visible and not hourglass.texture and ResourceLoader.exists(HOURGLASS_ICON_PATH):
		hourglass.texture = load(HOURGLASS_ICON_PATH)
	hourglass.visible = duration.visible and hourglass.texture != null
	custom_minimum_size = icon.size

	if duration.visible:
		custom_minimum_size = duration.size + duration.position
	elif stacks.visible:
		custom_minimum_size = stacks.size + stacks.position

	if not status.status_changed.is_connected(_on_status_changed):
		status.status_changed.connect(_on_status_changed)

	_on_status_changed()

func _on_status_changed() -> void:
	if not status:
		return

	if status.can_expire and status.duration <= 0:
		queue_free()
		
	if status.stack_type == Status.StackType.INTENSITY and status.stacks == 0:
		queue_free()

	duration.text = str(status.duration)
	stacks.text = str(status.stacks)

func _exit_tree() -> void:
	status._exit_tree()
