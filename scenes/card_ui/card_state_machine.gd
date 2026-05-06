class_name CardStateMachine
extends Node

@export var initial_state: CardState

var current_state: CardState
var states := {}

func init(card: CardUI) -> void:
	for child in get_children():
		if child is CardState:
			states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
			#Events.finished_selecting_cards_from_hand.connect(_on_finished_selecting_cards_from_hand)
			child.card_ui = card
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state
	
	

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
			_log("transition rejected: requested %s → %s, but current is %s" % [
				_state_name(from.state),
				_state_name(to),
				_state_name(current_state.state) if current_state else "<none>",
			])
			return

		var new_state: CardState = states[to]
		if not new_state:
			_log("transition failed: no state for %s" % _state_name(to))
			return

		_log("%s → %s" % [_state_name(current_state.state), _state_name(to)])

		if current_state:
			current_state.exit()

		new_state.enter()
		current_state = new_state
		new_state.post_enter()

#func _on_finished_selecting_cards_from_hand(_cards: Array[CardUI]) -> void:
func force_return_to_base_state() -> void:
	var new_state: CardState = states[CardState.State.BASE]
	_log("force_return_to_base_state from %s" % (_state_name(current_state.state) if current_state else "<none>"))

	if current_state:
		current_state.exit()

	new_state.enter()
	current_state = new_state
	new_state.post_enter()


func _state_name(s: int) -> String:
	return CardState.State.keys()[s]


func _log(msg: String) -> void:
	var id := "?"
	if current_state and current_state.card_ui and current_state.card_ui.card:
		id = current_state.card_ui.card.id
	print("[CardSM][%s] %s" % [id, msg])
