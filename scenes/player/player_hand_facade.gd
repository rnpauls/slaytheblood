## Player-side HandFacade. The player's "hand" is the set of PlayerCardUI
## children of the Hand control; there is no data-side Array[Card] mirror.
## We materialize the hand on demand by walking the visual children.
##
## Discards go through PlayerCardUI.discard() so the existing visual handoff
## (fly-to-discard-pile + emit Events.card_discarded → PlayerHandler triggers
## downstream side effects like Enraged) keeps working untouched.
##
## Exhaust just queue_frees the visual — the Card resource is not added to
## any pile, matching the existing ExhaustRandomEffect semantics.
class_name PlayerHandFacade
extends HandFacade

var _player: Player
var _player_handler: PlayerHandler


func _init(player: Player, player_handler: PlayerHandler) -> void:
	_player = player
	_player_handler = player_handler


# ── Queries ───────────────────────────────────────────────────────────────────

func get_hand() -> Array[Card]:
	var result: Array[Card] = []
	for child in _player_handler.hand.get_children():
		if child is PlayerCardUI:
			result.append((child as PlayerCardUI).card)
	return result

func size() -> int:
	return _player_handler.hand.get_child_count()

func is_intimidated(card: Card) -> bool:
	return _player.intimidated_cards.has(card)


# ── Mutations ────────────────────────────────────────────────────────────────

func discard_random(n: int) -> Array[Card]:
	var card_uis := _shuffled_card_uis()
	var to_discard := card_uis.slice(0, n)
	var discarded: Array[Card] = []
	for card_ui: PlayerCardUI in to_discard:
		discarded.append(card_ui.card)
		card_ui.discard()
	return discarded


func discard_random_filtered(predicate: Callable, n: int) -> Array[Card]:
	var card_uis := _shuffled_card_uis().filter(
		func(cu: PlayerCardUI) -> bool: return predicate.call(cu.card))
	var to_discard := card_uis.slice(0, n)
	var discarded: Array[Card] = []
	for card_ui: PlayerCardUI in to_discard:
		discarded.append(card_ui.card)
		card_ui.discard()
	return discarded


func exhaust_random(n: int) -> Array[Card]:
	var card_uis := _shuffled_card_uis()
	var to_exhaust := card_uis.slice(0, n)
	var exhausted: Array[Card] = []
	for card_ui: PlayerCardUI in to_exhaust:
		exhausted.append(card_ui.card)
		_player_handler.character.exhaust.add_card(card_ui.card)
		card_ui.queue_free()
	return exhausted


func draw_cards(n: int) -> Tween:
	return _player_handler.draw_cards(n)


func reshuffle_discard() -> void:
	_player_handler.reshuffle_deck_from_discard()


# ── Helpers ──────────────────────────────────────────────────────────────────

func _shuffled_card_uis() -> Array:
	var card_uis := _player_handler.hand.get_children().duplicate()
	RNG.array_shuffle(card_uis)
	return card_uis
