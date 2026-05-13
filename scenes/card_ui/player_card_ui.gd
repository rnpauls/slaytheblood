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
	Events.player_action_phase_started.connect(_on_player_action_phase_started)
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

func _set_modifier_handler(value: ModifierHandler) -> void:
	if modifier_handler == value:
		return
	if modifier_handler and modifier_handler.modifiers_changed.is_connected(_on_modifiers_changed):
		modifier_handler.modifiers_changed.disconnect(_on_modifiers_changed)
	super._set_modifier_handler(value)
	if modifier_handler and not modifier_handler.modifiers_changed.is_connected(_on_modifiers_changed):
		modifier_handler.modifiers_changed.connect(_on_modifiers_changed)
	_propagate_modifier_handler()

func _propagate_modifier_handler() -> void:
	# Hand.gd assigns modifier_handler before add_child, so @onready vars aren't
	# initialized yet — wait for _ready before touching card_render.
	if not is_node_ready():
		await ready
	if card_render and card_render.card_visuals:
		card_render.card_visuals.modifier_handler = modifier_handler
		card_render.card_visuals.refresh_modified_values()

func _on_modifiers_changed() -> void:
	if card_render and card_render.card_visuals:
		card_render.card_visuals.refresh_modified_values()

func _on_char_stats_changed() -> void:
	if card:
		playable = char_stats.can_play_card(card)
		# Refresh dynamic-cost cards (Rune Bolt, Cascade Strike, Final Salvo)
		# whenever stats tick — runechants/attacks_this_turn/discards_this_combat
		# all flow through stats_changed.
		if card_render and card_render.card_visuals:
			card_render.card_visuals.refresh_cost()

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
	if card_render.card_visuals:
		# tint_cost gates whether refresh_modified_values touches the cost
		# label's font_color — keeps our unplayable-red override below winning.
		card_render.card_visuals.tint_cost = playable
		if not playable:
			card_render.card_visuals.cost.add_theme_color_override("font_color", Color.RED)
		else:
			card_render.card_visuals.cost.remove_theme_color_override("font_color")
			# Reapply modifier tint to cost (and refresh attack/defense — cheap).
			card_render.card_visuals.refresh_modified_values()

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

func _on_player_action_phase_started() -> void:
	disabled = false
