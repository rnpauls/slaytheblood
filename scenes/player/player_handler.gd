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
@export var hand_left_weapon: WeaponHandler
@export var hand_right_weapon: WeaponHandler
@export var hand_left_equipment: EquipmentHandler
@export var hand_right_equipment: EquipmentHandler
@export var equipment_head: EquipmentHandler
@export var equipment_chest: EquipmentHandler
@export var equipment_arms: EquipmentHandler
@export var equipment_legs: EquipmentHandler
@export var player: Player
@export var hand: Hand

var character: CharacterStats

# First-card / first-attack tracking (per turn). Reset in start_turn() and
# polled in _on_card_play_finished to fire the corresponding global signals
# exactly once per turn.
var _first_card_played_this_turn: bool = false
var _first_attack_played_this_turn: bool = false

func _ready() -> void:
	#Events.card_play_started.connect(_on_card_played) #Replaced with card.card_play_started / finished
	Events.card_discarded.connect(_on_card_discarded)
	# pitched / sunk / blocked are per-card signals now — connected in draw_card() so that
	# only player cards trigger these handlers (enemy cards never connect to them).


func start_battle(char_stats: CharacterStats) -> void:
	character = char_stats
	character.draw_pile = character.deck.custom_duplicate()
	character.draw_pile.shuffle()
	character.discard = CardPile.new()
	character.exhaust = CardPile.new()

	# Materialize the symmetric HandFacade for effects targeting the player.
	player.hand_facade = PlayerHandFacade.new(player, self)

	_assign_hand_slot(character.hand_left, hand_left_weapon, hand_left_equipment)
	_assign_hand_slot(character.hand_right, hand_right_weapon, hand_right_equipment)

	_assign_body_equipment_slot(character.equipment_head, equipment_head)
	_assign_body_equipment_slot(character.equipment_chest, equipment_chest)
	_assign_body_equipment_slot(character.equipment_arms, equipment_arms)
	_assign_body_equipment_slot(character.equipment_legs, equipment_legs)

	relics.relics_activated.connect(_on_relics_activated)
	player.status_handler.statuses_applied.connect(_on_statuses_applied)
	Events.player_set_up.emit()
	start_turn()


## Decide whether the slot holds a Weapon or an offhand Equipment, and route accordingly.
## The unused handler is hidden so only one is visible per side.
func _assign_hand_slot(slot_value: Resource, weapon_handler: WeaponHandler, equip_handler: EquipmentHandler) -> void:
	if slot_value is Weapon:
		weapon_handler.set_weapon(slot_value)
		weapon_handler.show()
		if equip_handler:
			equip_handler.set_equipment(null)
			equip_handler.hide()
	elif slot_value is Equipment:
		if equip_handler:
			equip_handler.owner_of_equipment = player
			equip_handler.set_equipment(slot_value)
			equip_handler.show()
		weapon_handler.set_weapon(null)
		weapon_handler.hide()
	else:
		# Empty slot.
		weapon_handler.set_weapon(null)
		weapon_handler.hide()
		if equip_handler:
			equip_handler.set_equipment(null)
			equip_handler.hide()


func _assign_body_equipment_slot(eq: Equipment, handler: EquipmentHandler) -> void:
	if not handler:
		return
	handler.owner_of_equipment = player
	handler.set_equipment(eq)
	if eq:
		handler.show()
	else:
		handler.hide()


func start_turn() -> void:
	character.block = 0
	character.reset_mana()
	character.reset_action_points()
	_first_card_played_this_turn = false
	_first_attack_played_this_turn = false
	relics.activate_relics_by_type(Relic.Type.START_OF_TURN)
	reset_weapons()

func end_turn() -> void:
	hand.disable_hand()
	relics.activate_relics_by_type(Relic.Type.END_OF_TURN)


func draw_card() -> void:
	if not character:
		await Events.player_set_up
	# Auto-recycle: when the draw pile is empty, flip the discard pile back onto
	# it (no shuffle). reshuffle_deck_from_discard handles the visual handoff +
	# the synchronous resource swap; subsequent draws work immediately.
	if character.draw_pile.empty() and not character.discard.empty():
		reshuffle_deck_from_discard()
	# Release the top visual from the draw pile BEFORE popping the resource so
	# the panel's size_changed handler sees matching counts and skips auto-removal.
	var battle_ui := get_tree().get_first_node_in_group("ui_layer") as BattleUI
	var source_visual: CardUI = null
	if battle_ui and battle_ui.draw_pile:
		source_visual = battle_ui.draw_pile.release_top_visual()
	var card_drawn: Card = character.draw_pile.draw_card()
	if card_drawn:
		hand.add_card(card_drawn, source_visual)
		SFXRegistry.play(&"DRAW_CARD")
		Events.player_card_drawn.emit()
		card_drawn.card_play_finished.connect(_on_card_play_finished)
		card_drawn.card_play_started.connect(_on_card_play_started)
		card_drawn.pitched.connect(_on_card_pitched)
		card_drawn.sunk.connect(_on_card_sunk)
		card_drawn.blocked.connect(_on_card_blocked)
		card_drawn.owner = player
	elif source_visual:
		# Edge case: visual released but no card to draw (resource desync). Free it.
		source_visual.queue_free()


func draw_cards(amount: int, hand_type = null) -> Tween:
	if amount == 0:
		if hand_type == 'init':
			hand.enable_hand()
			return null
		elif hand_type == 'end':
			Events.player_hand_drawn.emit()
		return null

	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		tween.tween_interval(HAND_DRAW_INTERVAL)
	if hand_type == 'init':
		tween.finished.connect(
			func():
				hand.enable_hand()
				Events.player_initial_hand_drawn.emit()
		)
	if hand_type == 'end':
		tween.finished.connect(
			func():
				Events.player_hand_drawn.emit()
		)
	return tween

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
		# card_ui.discard() flies the live visual to the discard pile AND triggers
		# card.discard_card() → Events.card_discarded → _on_card_discarded, which
		# adds the card to the resource pile (skipping exhaust cards).
		tween.tween_callback(card_ui.discard)
		tween.tween_interval(HAND_DISCARD_INTERVAL)

	tween.finished.connect(
		func():
			Events.player_hand_discarded.emit()
	)


## Flip the discard pile onto the draw pile in original order — NOT shuffled.
## Order: discard.cards[0] (oldest) becomes draw_pile.cards[0] (next to draw),
## discard.cards[-1] (newest) becomes draw_pile.cards[-1] ("bottom of new
## deck" per user spec).
##
## Implementation note: the resource swap is ATOMIC — we duplicate the array
## once, clear discard, assign to draw, and emit size_changed exactly once on
## each pile AFTER the visual handoff is done. The naive while-loop of
## draw_card/add_card emits N intermediate size_changed events that each see a
## mismatched visual-vs-resource count (because reshuffle_to has already moved
## all visuals), and each one runs _sync_to_resource which spawns or frees
## anonymous CardUIs to "fix" the diff. Those phantom CardUIs land in the
## discard panel as the default-card placeholder and stick around after the
## reshuffle completes.
func reshuffle_deck_from_discard() -> void:
	if not character.draw_pile.empty():
		return
	if character.discard.empty():
		return

	# Animate the visual handoff first so the size_changed events emitted by
	# the atomic swap below see matching visual/resource counts and skip
	# auto-spawn/free.
	var battle_ui := get_tree().get_first_node_in_group("ui_layer") as BattleUI
	if battle_ui and battle_ui.discard_pile and battle_ui.draw_pile:
		battle_ui.discard_pile.reshuffle_to(battle_ui.draw_pile)

	# Atomic resource swap (preserves order — no shuffle).
	var moving := character.discard.cards.duplicate()
	character.discard.cards.clear()
	character.draw_pile.cards = moving
	character.discard.card_pile_size_changed.emit(0)
	character.draw_pile.card_pile_size_changed.emit(character.draw_pile.cards.size())

func _on_card_play_started(_card: Card) -> void:
	pass

func _on_card_play_finished(card: Card) -> void:
	if card.type == Card.Type.ATTACK:
		player.attack_completed.emit()
		Events.player_attack_completed.emit() #Needed for relics e.g. ira
		if not _first_attack_played_this_turn:
			_first_attack_played_this_turn = true
			Events.player_first_attack_played.emit(card)
	if not _first_card_played_this_turn:
		_first_card_played_this_turn = true
		Events.player_first_card_played.emit(card)
	if card.exhausts:# or card.type == Card.Type.POWER:
		character.exhaust.add_card(card)
		Events.card_exhausted.emit(card)
		return
	character.discard.add_card(card) #This used to happen at the start of card.play()

func _on_card_discarded(card: Card) -> void:
	if card.attack >= 6:
		var enr_status  := preload("res://statuses/enraged.tres").duplicate()
		player.status_handler.add_status(enr_status)

	if card.exhausts:# or card.type == Card.Type.POWER:
		character.exhaust.add_card(card)
		Events.card_exhausted.emit(card)
		return
	character.discard.add_card(card)

func _on_card_blocked(card: Card) -> void:
	character.discard.add_card(card)

func _on_card_pitched(card: Card) -> void:
	if card.cost == 0:
		var flow_status  := preload("res://statuses/flow.tres").duplicate()
		player.status_handler.add_status(flow_status)
	character.discard.add_card(card)

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
		Relic.Type.END_OF_COMBAT:
			restore_equipment_for_battle()


func reset_weapons() -> void:
	for wep in [hand_left_weapon, hand_right_weapon] as Array[WeaponHandler]:
		if wep and wep.weapon:
			wep.reset()


## Called at end of combat: REUSABLE equipment refreshes; ONE_SHOT was already cleaned up
## per-destruction in EquipmentHandler.
func restore_equipment_for_battle() -> void:
	for handler in [
		hand_left_equipment, hand_right_equipment,
		equipment_head, equipment_chest, equipment_arms, equipment_legs,
	] as Array[EquipmentHandler]:
		if handler:
			handler.restore_for_battle()
