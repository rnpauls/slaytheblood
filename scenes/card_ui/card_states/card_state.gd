class_name CardState
extends Node

enum State {BASE, CLICKED, DRAGGING, AIMING, RELEASED, PITCHED, BLOCKED, SELECTED}

signal transition_requested(from: CardState, to: State)

@export var state: State

var card_ui: CardUI

func enter() -> void:
	pass

func post_enter() -> void:
	pass

func exit() -> void:
	pass

func on_input(_event: InputEvent) -> void:
	pass

func on_gui_input(_event: InputEvent) -> void:
	pass

func on_mouse_entered() -> void:
	pass

func on_mouse_exited() -> void:
	pass

func _log(msg: String) -> void:
	var id := "?"
	if card_ui and card_ui.card:
		id = card_ui.card.id
	print("[CardSM][%s] %s" % [id, msg])
