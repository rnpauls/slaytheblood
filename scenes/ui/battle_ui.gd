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
var _exhaust_button_tween: Tween

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.player_initial_hand_drawn.connect(_on_player_initial_hand_drawn)
	Events.player_action_phase_started.connect(_on_player_action_phase_started)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", true))
	discard_pile.pressed.connect(_on_discard_pile_pressed)
	exhaust_button.pressed.connect(exhaust_pile_view.show_current_view.bind("Exhaust Pile"))
	exhaust_button.pivot_offset = exhaust_button.size / 2.0
	exhaust_button.mouse_entered.connect(_on_exhaust_button_mouse_entered)
	exhaust_button.mouse_exited.connect(_on_exhaust_button_mouse_exited)
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.enemy_phase_ended.connect(_on_enemy_phase_ended)
	Events.top_card_reveal_requested.connect(_on_top_card_reveal_requested)
	Events.card_add_animation_requested.connect(_on_card_add_animation_requested)

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

## Prompt the player to pick `num_cards` from their hand. Awaits user input
## and returns the chosen CardUIs. Optional prompt_text overrides the default
## "Choose N cards" label so card scripts can show a verb-specific prompt
## (e.g. "Sink a card", "Exhaust a card"). Most callers should go through
## PlayerHandFacade.prompt_choose_cards rather than calling this directly.
func choose_cards_in_hand(num_cards: int, prompt_text: String = "") -> Array[CardUI]:
	num_cards_to_choose = num_cards
	choice_screen_label.text = prompt_text if not prompt_text.is_empty() else "Choose %s cards" % num_cards_to_choose
	choice_screen.show()
	Events.selecting_cards_from_hand.emit(num_cards_to_choose)
	var selected_cards: Array[CardUI] = await Events.finished_selecting_cards_from_hand
	return selected_cards

func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value 
	mana_ui.char_stats = char_stats
	action_points_ui.char_stats = char_stats
	hand.char_stats = char_stats

## EOT cleanup completed and the hand is back at full size. Disable the end
## turn button — it stays disabled until the enemy declares an attack (flips
## it to BLOCK) or the enemy phase ends (returns it to END TURN). Also emit
## player_turn_ended for status effects (intimidated/poison_tip/empowered)
## that hook into "the player's turn just ended".
func _on_player_hand_drawn() -> void:
	print_debug("[EndBtn] disable from _on_player_hand_drawn (post-EOT)")
	end_turn_button.disabled = true
	Events.player_turn_ended.emit()

func _on_player_initial_hand_drawn() -> void:
	print_debug("[EndBtn] enable from _on_player_initial_hand_drawn")
	waiting_for_battle_start = false
	end_turn_button.disabled = false

func _on_player_action_phase_started() -> void:
	if waiting_for_battle_start:
		print_debug("[EndBtn] _on_player_action_phase_started skipped (waiting_for_battle_start)")
	else:
		print_debug("[EndBtn] enable from _on_player_action_phase_started")
		end_turn_button.disabled = false

func _on_end_turn_button_pressed() -> void:
	print_debug("[EndBtn] disable from _on_end_turn_button_pressed (text=%s)" % end_turn_button.text)
	end_turn_button.disabled = true
	if end_turn_button.text == "END TURN":
		Events.player_end_phase_started.emit()
	elif end_turn_button.text == "BLOCK":
		end_turn_button.text = "END TURN"
		Events.player_blocks_declared.emit()

func _on_enemy_attack_declared() -> void:
	#is_blocking = true
	print_debug("[EndBtn] enable+BLOCK from _on_enemy_attack_declared")
	end_turn_button.text = "BLOCK"
	end_turn_button.disabled = false

func _on_enemy_phase_ended() -> void:
	print_debug("[EndBtn] enable+END TURN from _on_enemy_phase_ended")
	end_turn_button.text = "END TURN"
	end_turn_button.disabled = false


func _on_exhaust_button_mouse_entered() -> void:
	if _exhaust_button_tween and _exhaust_button_tween.is_running():
		_exhaust_button_tween.kill()
	_exhaust_button_tween = exhaust_button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_exhaust_button_tween.tween_property(exhaust_button, "scale", Vector2.ONE * 1.15, Constants.TWEEN_UI_HOVER)


func _on_exhaust_button_mouse_exited() -> void:
	if _exhaust_button_tween and _exhaust_button_tween.is_running():
		_exhaust_button_tween.kill()
	_exhaust_button_tween = exhaust_button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_exhaust_button_tween.tween_property(exhaust_button, "scale", Vector2.ONE, Constants.TWEEN_UI_HOVER)


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


## Routes a CardAddEffect animation request to the right visual handler. The
## emit happens BEFORE the resource pile is mutated; for player draw/discard
## destinations, the called CardStackPanel.animate_card_in does the visual
## handoff (parent CardUI in, mark _pitched_in_flight) so the immediately-
## following size_changed handler skips its auto-spawn. For HAND, we hold a
## temp visual at center then trigger the existing hand.add_card flow. For
## enemy targets there's no pile UI to hand off to — we just play a fly-to-
## label flair and free the visual.
func _on_card_add_animation_requested(card: Card, target: Node, destination: int) -> void:
	if not card or not target:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var source_pos: Vector2 = (viewport_size - CardStackPanel.CARD_SIZE_UNSCALED) / 2.0

	if target is Player:
		match destination:
			CardAddEffect.Destination.HAND:
				if hand:
					_animate_card_to_hand(card, source_pos)
			CardAddEffect.Destination.DISCARD_PILE:
				if discard_pile:
					discard_pile.animate_card_in(card, source_pos)
			_:
				if draw_pile:
					draw_pile.animate_card_in(card, source_pos)
	elif target is Enemy:
		_animate_card_to_enemy_label(card, target as Enemy, destination, source_pos)


func _animate_card_to_hand(card: Card, source_pos: Vector2) -> void:
	var temp := _TRANSIENT_REVEAL_CARD_UI_SCENE.instantiate() as CardUI
	add_child(temp)
	temp.card = card
	if temp.card_render:
		temp.card_render.show_back = false
	temp.global_position = source_pos
	temp.scale = Vector2.ONE
	temp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp.z_index = 100
	# Hold at center so the player can read the card, then trigger the existing
	# draw-style entry: hand.add_card consumes the temp visual (queue_free'd
	# inside add_card) and starts a new PlayerCardUI at the temp's transform.
	var t := temp.create_tween()
	t.tween_interval(0.3)
	t.tween_callback(func():
		if is_instance_valid(temp) and is_instance_valid(hand):
			hand.add_card(card, temp))


func _animate_card_to_enemy_label(card: Card, enemy: Enemy, destination: int, source_pos: Vector2) -> void:
	if not enemy or not enemy.enemy_resource_ui:
		return
	var resource_ui := enemy.enemy_resource_ui
	var target_label: Control = (
		resource_ui.discard_count
		if destination == CardAddEffect.Destination.DISCARD_PILE
		else resource_ui.deck_count
	)
	if not target_label:
		return
	var visual := _TRANSIENT_REVEAL_CARD_UI_SCENE.instantiate() as CardUI
	add_child(visual)
	visual.card = card
	if visual.card_render:
		visual.card_render.show_back = false
	visual.global_position = source_pos
	visual.scale = Vector2.ONE
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.z_index = 100
	# Aim the card's center at the label's center.
	var card_center_offset: Vector2 = (CardStackPanel.CARD_SIZE_UNSCALED * CardStackPanel.PILE_SCALE) / 2.0
	var label_center: Vector2 = target_label.global_position + target_label.size / 2.0
	var target_pos: Vector2 = label_center - card_center_offset

	var t := visual.create_tween()
	t.tween_interval(0.3)
	t.tween_property(visual, "global_position", target_pos, 0.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "scale", Vector2(CardStackPanel.PILE_SCALE, CardStackPanel.PILE_SCALE), 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "modulate:a", 0.0, 0.4).set_delay(0.2)
	t.tween_callback(func():
		if is_instance_valid(visual):
			visual.queue_free())
