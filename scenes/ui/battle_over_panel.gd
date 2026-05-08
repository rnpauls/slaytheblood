class_name BattleOverPanel
extends Panel

const MAIN_MENU = "res://scenes/ui/main_menu.tscn"

enum Type {WIN, LOSE, STALEMATE}

@onready var label: Label = %Label
@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton

var _current_type: Type = Type.WIN


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	main_menu_button.pressed.connect(get_tree().change_scene_to_file.bind(MAIN_MENU))
	Events.battle_over_screen_requested.connect(show_screen)


func show_screen(text: String, type: Type) -> void:
	_current_type = type
	label.text = text
	continue_button.visible = type == Type.WIN or type == Type.STALEMATE
	main_menu_button.visible = type == Type.LOSE
	show()
	get_tree().paused = true


func _on_continue_pressed() -> void:
	if _current_type == Type.STALEMATE:
		Events.battle_stalemated.emit()
	else:
		Events.battle_won.emit()
