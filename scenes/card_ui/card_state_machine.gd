class_name CardStateMachine
extends Node

@export var initial_state: CardState

var current_state: CardState
var states := {}
var is_blocking:= false

func init(card: CardUI) -> void:
	var is_blocking = false
	for child in get_children():
		if child is CardState:
			states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
			child.card_ui = card
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state
	
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.player_blocks_declared.connect(_on_player_blocks_declared)
	

func on_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_input(event)

func on_gui_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_gui_input(event)

func on_mouse_entered() -> void:
	if current_state:
		current_state.on_mouse_entered()

func on_mouse_exited() -> void:
	if current_state:
		current_state.on_mouse_exited()

func _on_transition_requested(from: CardState, to: CardState.State) -> void:
		if from != current_state:
			return
		
		var new_state: CardState = states[to]
		if not new_state:
			return
		
		if current_state:
			current_state.exit()
		
		new_state.enter()
		current_state = new_state
		new_state.post_enter()
	

func _on_enemy_attack_declared() -> void:
	is_blocking = true

func _on_player_blocks_declared() -> void:
	is_blocking = false
