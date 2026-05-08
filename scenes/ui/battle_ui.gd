class_name BattleUI
extends CanvasLayer

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var hand: Hand = $Hand
@onready var mana_ui: ManaUI = $ManaUI
@onready var action_points_ui: ActionPointsUI = $ActionPointsUI
@onready var end_turn_button: Button = %EndTurnButton
@onready var draw_pile: CardStackPanel = %DrawPile
@onready var discard_pile: CardStackPanel = %DiscardPile
@onready var exhaust_button: TextureButton = %ExhaustButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
@onready var exhaust_pile_view: CardPileView = %ExhaustPileView
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
	draw_pile.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", true))
	discard_pile.pressed.connect(_on_discard_pile_pressed)
	exhaust_button.pressed.connect(exhaust_pile_view.show_current_view.bind("Exhaust Pile"))
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.enemy_phase_ended.connect(_on_enemy_phase_ended)
	Events.top_card_reveal_requested.connect(_on_top_card_reveal_requested)

func initialize_card_pile_ui() ->void:
	draw_pile.card_pile = char_stats.draw_pile
	draw_pile_view.card_pile = char_stats.draw_pile
	discard_pile.card_pile = char_stats.discard
	discard_pile_view.card_pile = char_stats.discard
	exhaust_pile_view.card_pile = char_stats.exhaust


## The player's discard pile click rebinds the view to the player's discard
## first — this is the trigger that resets the view if it was retargeted to
## an enemy's discard via show_card_pile().
func _on_discard_pile_pressed() -> void:
	discard_pile_view.card_pile = char_stats.discard
	discard_pile_view.show_current_view("Discard Pile")


## Open the discard-pile viewer retargeted to an arbitrary CardPile (used by
## the EnemyResourceUI trash button to show an enemy's discard). The next click
## on the player's discard pile re-binds back to char_stats.discard.
func show_card_pile(pile: CardPile, title: String) -> void:
	discard_pile_view.card_pile = pile
	discard_pile_view.show_current_view(title)

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


## Routes top-card-reveal requests to the right visual handler. Player owners
## use the on-screen draw pile; enemy owners (no visual pile yet) use a
## transient overlay near screen center. Either path eventually emits
## `Events.top_card_reveal_finished` so the caller can resume.
func _on_top_card_reveal_requested(card: Card, source_owner: Node) -> void:
	if source_owner is Player and draw_pile:
		draw_pile.reveal_top(card)
	else:
		_transient_top_card_reveal(card)


const _TRANSIENT_REVEAL_CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

func _transient_top_card_reveal(card: Card) -> void:
	var visual := _TRANSIENT_REVEAL_CARD_UI_SCENE.instantiate() as CardUI
	add_child(visual)
	visual.card_render.show_back = true
	visual.card = card
	var viewport_size := get_viewport().get_visible_rect().size
	visual.global_position = (viewport_size - CardStackPanel.CARD_SIZE_UNSCALED) / 2.0
	visual.scale = Vector2.ONE
	visual.z_index = 100

	var t := visual.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(Constants.TWEEN_CARD_FLIP)
	t.tween_property(visual, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP)
	t.tween_callback(func():
		if is_instance_valid(visual) and visual.card_render:
			visual.card_render.show_back = false)
	t.tween_property(visual, "scale:x", 1.0, Constants.TWEEN_CARD_FLIP)
	t.tween_interval(0.6)
	t.tween_property(visual, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP)
	t.tween_callback(func():
		if is_instance_valid(visual) and visual.card_render:
			visual.card_render.show_back = true)
	t.tween_property(visual, "scale:x", 1.0, Constants.TWEEN_CARD_FLIP)
	t.tween_callback(func():
		if is_instance_valid(visual):
			visual.queue_free()
		Events.top_card_reveal_finished.emit())
