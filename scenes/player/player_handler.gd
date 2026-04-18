# Player turn order:
# 1. START_OF_TURN Relics 
# 2. START_OF_TURN Statuses
# 3. Action phase started signal
# 4. End turn button
# 5. END_OF_TURN Relics 
# 6. END_OF_TURN Statuses
# 7. End of turn cleanup (reset mana, action points, and draw back up)
class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.25

@export var relics: RelicHandler
@export var weapon_left: WeaponHandler
@export var weapon_right: WeaponHandler
@export var player: Player
@export var hand: Hand

var character: CharacterStats


func _ready() -> void:
	Events.card_played.connect(_on_card_played)
	Events.card_discarded.connect(_on_card_discarded)
	Events.card_pitched.connect(_on_card_pitched)
	Events.card_blocked.connect(_on_card_blocked)
	Events.card_sunk.connect(_on_card_sunk)


func start_battle(char_stats: CharacterStats) -> void:
	character = char_stats
	character.draw_pile = character.deck.custom_duplicate()
	character.draw_pile.shuffle()
	character.discard = CardPile.new()
	weapon_left.set_weapon(character.weapon_left)
	weapon_right.set_weapon(character.weapon_right)
	relics.relics_activated.connect(_on_relics_activated)
	player.status_handler.statuses_applied.connect(_on_statuses_applied)
	Events.player_set_up.emit()
	start_turn()


func start_turn() -> void:
	character.block = 0
	character.reset_mana()
	character.reset_action_points()
	relics.activate_relics_by_type(Relic.Type.START_OF_TURN)
	reset_weapons()

func end_turn() -> void:
	hand.disable_hand()
	relics.activate_relics_by_type(Relic.Type.END_OF_TURN)


func draw_card() -> void:
	#reshuffle_deck_from_discard()
	if not character:
		await Events.player_set_up
	var card_drawn: Card = character.draw_pile.draw_card()
	if card_drawn:
		hand.add_card(card_drawn)
		#reshuffle_deck_from_discard()
		Events.player_card_drawn.emit()


func draw_cards(amount: int, hand_type = null) -> void:
	if amount == 0:
		if hand_type == 'init':
			hand.enable_hand()
			return
		elif hand_type == 'end':
			Events.player_hand_drawn.emit()
		return

	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		tween.tween_interval(HAND_DRAW_INTERVAL)
	if hand_type == 'init':
		tween.finished.connect(
			#func(): Events.player_hand_drawn.emit()
			func(): 
				hand.enable_hand()
				Events.player_initial_hand_drawn.emit()
		)
	if hand_type == 'end':
		tween.finished.connect(
			func(): 
				Events.player_hand_drawn.emit()
		)
func end_turn_cleanup() -> void:
	character.reset_mana()
	character.action_points = 0
	draw_cards(character.cards_per_turn - hand.get_child_count(), 'end')


func discard_cards() -> void:
	if hand.get_child_count() == 0:
		Events.player_hand_discarded.emit()
		return

	var tween := create_tween()
	for card_ui: CardUI in hand.get_children():
		tween.tween_callback(character.discard.add_card.bind(card_ui.card))
		tween.tween_callback(hand.discard_card.bind(card_ui))
		tween.tween_interval(HAND_DISCARD_INTERVAL)
	
	tween.finished.connect(
		func():
			Events.player_hand_discarded.emit()
	)


func reshuffle_deck_from_discard() -> void:
	if not character.draw_pile.empty():
		return

	while not character.discard.empty():
		character.draw_pile.add_card(character.discard.draw_card())

	character.draw_pile.shuffle()


func _on_card_played(card: Card) -> void:
	if card.exhausts:# or card.type == Card.Type.POWER:
		return
	
	character.discard.add_card(card)

func _on_card_discarded(card: Card) -> void:
	if card.attack >= 6:
		var enr_status  := preload("res://statuses/enraged.tres").duplicate()
		player.status_handler.add_status(enr_status)
	
	if card.exhausts:# or card.type == Card.Type.POWER:
		return
	character.discard.add_card(card)

func _on_card_blocked(card: Card) -> void:
	character.discard.add_card(card)

func _on_card_pitched(card: Card) -> void:
	character.draw_pile.add_card(card)

func _on_card_sunk(card: Card) -> void:
	character.draw_pile.add_card(card)

func _on_statuses_applied(type: Status.Type) -> void:
	match type:
		Status.Type.START_OF_TURN:
			#print("Need to implement drawing cards at end of turn instead of start. Currently card draw signal controls turn flow")
			Events.player_action_phase_started.emit()
			hand.enable_hand()
		Status.Type.END_OF_TURN:
			end_turn_cleanup()


func _on_relics_activated(type: Relic.Type) -> void:
	match type:
		Relic.Type.START_OF_TURN:
			player.status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)
		Relic.Type.END_OF_TURN:
			player.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)

func reset_weapons() -> void:
	for wep in [weapon_left, weapon_right] as Array[WeaponHandler]:
		wep.reset()
