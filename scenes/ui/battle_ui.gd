class_name BattleUI
extends CanvasLayer

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var hand: Hand = $Hand
@onready var mana_ui: ManaUI = $ManaUI
@onready var action_points_ui: ActionPointsUI = $ActionPointsUI
@onready var end_turn_button: Button = %EndTurnButton
@onready var draw_pile_button: CardPileOpener = %DrawPileButton
@onready var discard_pile_button: CardPileOpener = %DiscardPileButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
@onready var choice_screen: ColorRect = %ChoiceScreen
@onready var choice_screen_label: RichTextLabel = %ChoiceScreenLabel

var waiting_for_battle_start:= true
var num_cards_to_choose: int = 0
#var is_blocking:= false

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.player_initial_hand_drawn.connect(_on_player_initial_hand_drawn)
	Events.player_action_phase_started.connect(_on_player_action_phase_started)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", true))
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("Discard Pile"))
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.enemy_phase_ended.connect(_on_enemy_phase_ended)

func initialize_card_pile_ui() ->void:
	draw_pile_button.card_pile = char_stats.draw_pile
	draw_pile_view.card_pile = char_stats.draw_pile
	discard_pile_button.card_pile = char_stats.discard
	discard_pile_view.card_pile = char_stats.discard

func choose_cards_in_hand(num_cards: int) -> Array[CardUI]:
	num_cards_to_choose = num_cards
	choice_screen_label.text = "Choose %s cards" % num_cards_to_choose
	choice_screen.show()
	Events.selecting_cards_from_hand.emit()
	var selected_cards: Array[CardUI] = await Events.finished_selecting_cards_from_hand
	return selected_cards

func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value 
	mana_ui.char_stats = char_stats
	action_points_ui.char_stats = char_stats
	hand.char_stats = char_stats

func _on_player_hand_drawn() -> void:
	end_turn_button.disabled = true
	print_debug("End turn is emitted from battle_ui, but it does nothing here anymore")
	Hook.after_turn_end("player")
	Events.player_turn_ended.emit()

func _on_player_initial_hand_drawn() -> void:
	waiting_for_battle_start = false
	end_turn_button.disabled = false

func _on_player_action_phase_started() -> void:
	if waiting_for_battle_start:
		pass
	else:
		end_turn_button.disabled = false

func _on_end_turn_button_pressed() -> void:
	end_turn_button.disabled = true
	if end_turn_button.text == "END":
		Events.player_end_phase_started.emit()
	elif end_turn_button.text == "BLOCK":
		end_turn_button.text = "END"
		Events.player_blocks_declared.emit()

func _on_enemy_attack_declared() -> void:
	#is_blocking = true
	end_turn_button.text = "BLOCK"
	end_turn_button.disabled = false

func _on_enemy_phase_ended() -> void:
	end_turn_button.text = "END"
	end_turn_button.disabled = false


func _on_confirm_button_pressed() -> void:
	var chosen_cards: Array[CardUI]
	for tempcard in hand.get_children():
		if tempcard.selected:
			chosen_cards.append(tempcard)
	if chosen_cards.size() == num_cards_to_choose:
		Events.finished_selecting_cards_from_hand.emit(chosen_cards)
		choice_screen.hide()
