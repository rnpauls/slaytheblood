## Owns the data hand for an Enemy and keeps it in sync with EnemyHand (visual)
## and EnemyAI (planner). Extracted from enemy.gd so that a single component
## owns hand mutations: draw, add, remove, exhaust-EOT, AI-driven removal.
##
## Public surface (called by Enemy facade and EnemyHandFacade in Item 5):
##   draw_card()
##   draw_cards(amount) -> Tween
##   add_card_to_hand(card)
##   exhaust_fleeting_in_hand()     — burn fleeting cards at EOT
##   remove_card(card)              — manual removal (e.g. defense path)
##   get_card_ui(card) -> EnemyCardUI
##   set_pending_stage(card)        — flag the next card to be staged so the
##   clear_pending_stage()            AI-removal handler skips its visual drop
##   is_pending_stage(card) -> bool
##
## Emits `hand_changed` after every mutation; Enemy listens to refresh
## intent / plan colors / resource UI in one place.
class_name EnemyHandManager
extends Node

const ENEMY_CARD_UI_SCENE := preload("res://scenes/card_ui/enemy_card_ui.tscn")
## Delay between successive card draws (seconds), matching player hand feel.
const DRAW_INTERVAL := 0.12

signal hand_changed

var hand: Array[Card] = []
var card_ui_map: Dictionary = {}   # Card -> EnemyCardUI

var _enemy: Enemy
var _enemy_hand: EnemyHand
var _pending_stage_card: Card = null


func setup(enemy: Enemy, enemy_hand: EnemyHand) -> void:
	_enemy = enemy
	_enemy_hand = enemy_hand


## Connect to enemy_ai's removal signal. Called by Enemy.setup_ai after the AI
## node is instantiated.
func connect_to_ai(enemy_ai: EnemyAI) -> void:
	if not enemy_ai.card_removed_from_hand.is_connected(_on_ai_card_removed_from_hand):
		enemy_ai.card_removed_from_hand.connect(_on_ai_card_removed_from_hand)


# ── Pending-stage coordination ────────────────────────────────────────────────

## ActionSequencer flags the upcoming action card so _on_ai_card_removed_from_hand
## doesn't animate it out of EnemyHand — staged_display.stage() will reparent it.
func set_pending_stage(card: Card) -> void:
	_pending_stage_card = card

func clear_pending_stage() -> void:
	_pending_stage_card = null

func is_pending_stage(card: Card) -> bool:
	return card == _pending_stage_card


# ── Mutations ────────────────────────────────────────────────────────────────

func draw_card() -> void:
	# Auto-recycle: empty draw pile flips the discard back onto draw (no shuffle).
	if _enemy.stats.draw_pile.empty() and not _enemy.stats.discard.empty():
		reshuffle_discard()
	var card_drawn: Card = _enemy.stats.draw_pile.draw_card()
	if card_drawn == null:
		return
	hand.append(card_drawn)
	Events.enemy_card_drawn.emit(_enemy)
	card_drawn.owner = _enemy
	_connect_lifecycle_signals(card_drawn)
	var card_ui := _enemy_hand.add_card(card_drawn, _enemy.stats, _enemy.modifier_handler)
	card_ui_map[card_drawn] = card_ui
	_log("drew %s  (hand %d, ui_map %d)" % [card_drawn.id, hand.size(), card_ui_map.size()])
	hand_changed.emit()


## Draw multiple cards with a stagger delay between each.
func draw_cards(amount: int) -> Tween:
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		if i < amount - 1:
			tween.tween_interval(DRAW_INTERVAL)
	return tween


## Add a card directly to the hand (skipping the draw pile). Used by
## CardAddEffect's HAND destination.
func add_card_to_hand(card: Card) -> void:
	hand.append(card)
	Events.enemy_card_drawn.emit(_enemy)
	card.owner = _enemy
	_connect_lifecycle_signals(card)
	var card_ui := _enemy_hand.add_card(card, _enemy.stats, _enemy.modifier_handler)
	card_ui_map[card] = card_ui
	_log("added to hand %s  (hand %d, ui_map %d)" % [card.id, hand.size(), card_ui_map.size()])
	hand_changed.emit()


## Exhaust cards with `fleeting: true` from the hand at end of turn. Enemy hands
## persist across turns (no auto-discard), so this hook prevents clutter from
## fleeting cards (curses/trash injected by player effects, e.g. Gunkshot).
##
## Visual: each fleeting card runs CardUI._burn_up() (the same shader-driven
## dissolve player cards use when exhausted on play), instead of the plain
## fade-out used for normal mid-turn removal.
func exhaust_fleeting_in_hand() -> void:
	var to_exhaust: Array[Card] = []
	for card in hand:
		if card.fleeting:
			to_exhaust.append(card)
	if to_exhaust.is_empty():
		return

	# Capture each card_ui BEFORE the AI signal handler clears card_ui_map, and
	# reparent to the BattleUI overlay so _on_ai_card_removed_from_hand skips
	# its fade-out (it only fades cards still parented to _enemy_hand).
	var card_uis_to_burn: Array[EnemyCardUI] = []
	for card in to_exhaust:
		var card_ui: EnemyCardUI = card_ui_map.get(card, null)
		if is_instance_valid(card_ui):
			card_uis_to_burn.append(card_ui)
			card_ui._reparent_to_play_overlay()

	for card in to_exhaust:
		hand.erase(card)
		_enemy.stats.exhaust.add_card(card)
		if _enemy.enemy_ai:
			# AI removes from its own hand and re-plans via the signal handler below.
			_enemy.enemy_ai.card_removed_from_hand.emit(card)

	# Kick off all burn animations in parallel; wait for them to finish before
	# advancing the EOT phase.
	for card_ui in card_uis_to_burn:
		card_ui._burn_up()
	await _enemy.get_tree().create_timer(CardUI.BURN_DURATION + 0.05).timeout

	for card_ui in card_uis_to_burn:
		if is_instance_valid(card_ui):
			card_ui.queue_free()


## Remove a card from the data hand, the card_ui_map, and the EnemyHand display.
## Called when Enemy is in charge of the removal (defense, NAA, attack play).
func remove_card(card: Card) -> void:
	hand.erase(card)
	var card_ui: EnemyCardUI = card_ui_map.get(card, null)
	if is_instance_valid(card_ui) and card_ui.get_parent() == _enemy_hand:
		_enemy_hand.remove_card(card_ui)
	card_ui_map.erase(card)
	_log("remove_card: %s  (hand %d, ui_map %d)" % [card.id, hand.size(), card_ui_map.size()])
	hand_changed.emit()


## Erase the card_ui_map entry without touching the data hand or visual hand.
## ActionSequencer uses this when a card has been moved to the staged display.
func untrack_card_ui(card: Card) -> void:
	card_ui_map.erase(card)


## Flip the discard pile onto the draw pile in original order — NOT shuffled.
## Mirrors PlayerHandler.reshuffle_deck_from_discard so HandFacade sees a
## symmetric API on both sides. Resource-only — enemies have no visual pile,
## so the atomic swap is purely about avoiding N spurious draw_card debug
## prints during the move.
func reshuffle_discard() -> void:
	if not _enemy.stats.draw_pile.empty():
		return
	if _enemy.stats.discard.empty():
		return
	var moving := _enemy.stats.discard.cards.duplicate()
	_enemy.stats.discard.cards.clear()
	_enemy.stats.draw_pile.cards = moving
	_enemy.stats.discard.card_pile_size_changed.emit(0)
	_enemy.stats.draw_pile.card_pile_size_changed.emit(_enemy.stats.draw_pile.cards.size())


# ── Queries ───────────────────────────────────────────────────────────────────

func get_card_ui(card: Card) -> EnemyCardUI:
	return card_ui_map.get(card, null)


## Return the EnemyCardUI for card if it's tracked, otherwise create a transient
## one (for cards that aren't currently in the hand display).
func get_or_create_card_ui(card: Card) -> EnemyCardUI:
	var existing: EnemyCardUI = card_ui_map.get(card, null)
	if is_instance_valid(existing):
		return existing
	_log("WARNING: creating transient card_ui for %s (not in ui_map)" % card.id)
	var card_ui: EnemyCardUI = ENEMY_CARD_UI_SCENE.instantiate()
	_enemy.add_child(card_ui)
	card_ui.setup(card, _enemy.stats, _enemy.modifier_handler)
	card_ui.show_back = false
	return card_ui


# ── Card lifecycle handlers ───────────────────────────────────────────────────

## Mirror of player_handler's connect-on-draw pattern. Keeps enemy disposition
## in lockstep with the per-card signals emitted by Card.play / block_card /
## pitch_card / sink_card. Enemy handlers stay silent on the global Events bus
## so player relics (resonance_ring, lucky_charm) only fire on player actions.
##
## Cards persist across draws (discard → reshuffle → draw again is the same
## Card instance), so we guard each connect to avoid the Godot "already
## connected" error when a card is re-drawn after being played and recycled.
func _connect_lifecycle_signals(card: Card) -> void:
	if not card.card_play_finished.is_connected(_on_card_play_finished):
		card.card_play_finished.connect(_on_card_play_finished)
	if not card.blocked.is_connected(_on_card_blocked):
		card.blocked.connect(_on_card_blocked)
	if not card.pitched.is_connected(_on_card_pitched):
		card.pitched.connect(_on_card_pitched)
	if not card.sunk.is_connected(_on_card_sunk):
		card.sunk.connect(_on_card_sunk)


func _on_card_play_finished(card: Card) -> void:
	if card.exhausts:
		_enemy.stats.exhaust.add_card(card)
		return
	_enemy.stats.discard.add_card(card)


func _on_card_blocked(card: Card) -> void:
	_enemy.stats.exhaust.add_card(card)


func _on_card_pitched(card: Card) -> void:
	_enemy.stats.discard.add_card(card)


func _on_card_sunk(card: Card) -> void:
	_enemy.stats.draw_pile.add_card(card)


# ── AI signal handler ─────────────────────────────────────────────────────────

## Called when EnemyAI removes a card from its internal hand (pitch, play,
## block). Keeps the EnemyHand visual in sync without duplicating logic.
## NOTE: we do NOT erase from `hand` here — EnemyAI already did that.
func _on_ai_card_removed_from_hand(card: Card) -> void:
	_log("AI removed '%s'  ai_hand=%d  enemy_hand=%d  ui_map=%d" % [
		card.id, _enemy.enemy_ai.hand.size(), hand.size(), card_ui_map.size()])

	# If this card is about to be staged, skip the visual removal — the staged
	# display will reparent the same card_ui shortly. Animating it out here
	# would conflict.
	if card == _pending_stage_card:
		_log("  → skipping visual removal for '%s' (will be staged)" % card.id)
		card_ui_map.erase(card)
		hand_changed.emit()
		return

	var card_ui: EnemyCardUI = card_ui_map.get(card, null)
	if is_instance_valid(card_ui) and card_ui.get_parent() == _enemy_hand:
		_enemy_hand.remove_card(card_ui)
	card_ui_map.erase(card)
	hand_changed.emit()


func _log(msg: String) -> void:
	print("[EnemyHand:%s] %s" % [_enemy.stats.character_name if _enemy and _enemy.stats else "?", msg])
