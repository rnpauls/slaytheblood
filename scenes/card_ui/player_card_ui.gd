## Interactive card UI used in the player's hand.
## Adds the state machine, hover/drag/aim, playability checks, and event bindings
## on top of the base CardUI class.
class_name PlayerCardUI
extends CardUI

@onready var card_state_machine: CardStateMachine = $CardStateMachine as CardStateMachine
@onready var drop_point_detector: Area2D = %DropPointDetector
@onready var hover_overlay: CanvasLayer = get_node("/root/Run/HoverOverlay")

var playable := true : set = _set_playable
var disabled := true
var is_blocking := false
var selected := false


func _ready() -> void:
	Events.player_card_drawn.connect(_on_card_drawn)
	Events.card_aim_started.connect(_on_card_drag_or_aiming_started)
	Events.card_drag_started.connect(_on_card_drag_or_aiming_started)
	Events.card_aim_ended.connect(_on_card_drag_or_aim_ended)
	Events.card_drag_ended.connect(_on_card_drag_or_aim_ended)
	card_state_machine.init(self)

func _input(event: InputEvent) -> void:
	if _in_pile():
		return
	card_state_machine.on_input(event)


# True once the card has been handed off to a CardStackPanel (draw or discard).
# Used to gate hand-card behavior — state machine, hover-zoom, drag — on cards
# that are now decorative pile contents.
func _in_pile() -> bool:
	var p := get_parent()
	return p != null and p.has_method("accept_incoming_visual")

func select() -> void:
	selected = true

func deselect() -> void:
	selected = false

func _set_char_stats(value: Stats) -> void:
	super._set_char_stats(value)

func _on_char_stats_changed() -> void:
	if card:
		playable = char_stats.can_play_card(card)

func _set_playable(value: bool) -> void:
	playable = value
	if not is_node_ready():
		return
	# Pile cards keep their stats_changed connection but aren't interactable;
	# never glow them, even face-up in the discard pile.
	if _in_pile():
		card_render.set_glow(false)
		return
	card_render.set_glow(playable)
	if not playable:
		card_render.card_visuals.cost.add_theme_color_override("font_color", Color.RED)
	else:
		card_render.card_visuals.cost.remove_theme_color_override("font_color")

func _on_gui_input(event: InputEvent) -> void:
	if _in_pile():
		return
	card_state_machine.on_gui_input(event)

func _on_mouse_entered() -> void:
	if _in_pile():
		return
	card_state_machine.on_mouse_entered()

func _on_mouse_exited() -> void:
	if _in_pile():
		return
	card_state_machine.on_mouse_exited()

func _on_card_drag_or_aiming_started(used_card: Node) -> void:
	if used_card == self:
		return
	disabled = true

func _on_card_drag_or_aim_ended(_card: Node) -> void:
	disabled = false
	if char_stats and card:
		playable = char_stats.can_play_card(card)

func _on_card_drawn() -> void:
	if char_stats and card:
		playable = char_stats.can_play_card(card)
