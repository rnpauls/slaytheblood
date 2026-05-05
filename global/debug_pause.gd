extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_pause"):
		get_tree().paused = not get_tree().paused
		get_viewport().set_input_as_handled()
