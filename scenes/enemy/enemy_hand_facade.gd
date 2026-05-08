## Enemy-side HandFacade. The enemy's data hand lives on EnemyHandManager
## as Array[Card] (which is also aliased into EnemyAI.hand). Discards push
## the Card resource into stats.discard via card.discard_card() and remove
## it from the hand_manager (which animates the visual out of EnemyHand).
##
## Exhausts skip the discard pile entirely — only the data array and visual
## are removed.
class_name EnemyHandFacade
extends HandFacade

var _enemy: Enemy
var _hand_manager: EnemyHandManager


func _init(enemy: Enemy) -> void:
	_enemy = enemy
	_hand_manager = enemy.hand_manager


# ── Queries ───────────────────────────────────────────────────────────────────

func get_hand() -> Array[Card]:
	return _hand_manager.hand.duplicate()

func size() -> int:
	return _hand_manager.hand.size()

func is_intimidated(card: Card) -> bool:
	return _enemy.enemy_ai != null and _enemy.enemy_ai.intimidated_cards.has(card)

func has_arsenal() -> bool:
	return _enemy.enemy_ai != null and _enemy.enemy_ai.arsenal != null


# ── Mutations ────────────────────────────────────────────────────────────────

func discard_random(n: int) -> Array[Card]:
	var pool := _shuffled_hand()
	var to_discard: Array[Card] = []
	for c in pool.slice(0, n):
		to_discard.append(c)
	for card in to_discard:
		card.discard_card()
		_hand_manager.remove_card(card)
	return to_discard


func discard_random_filtered(predicate: Callable, n: int) -> Array[Card]:
	var pool := _hand_manager.hand.filter(predicate)
	RNG.array_shuffle(pool)
	var to_discard: Array[Card] = []
	for c in pool.slice(0, n):
		to_discard.append(c)
	for card in to_discard:
		card.discard_card()
		_hand_manager.remove_card(card)
	return to_discard


func exhaust_random(n: int) -> Array[Card]:
	var pool := _shuffled_hand()
	var to_exhaust: Array[Card] = []
	for c in pool.slice(0, n):
		to_exhaust.append(c)
	for card in to_exhaust:
		_enemy.stats.exhaust.add_card(card)
		_hand_manager.remove_card(card)
	return to_exhaust


func draw_cards(n: int) -> Tween:
	return _hand_manager.draw_cards(n)


func reshuffle_discard() -> void:
	_hand_manager.reshuffle_discard()


func destroy_arsenal() -> bool:
	return _enemy.destroy_arsenal()


# ── Helpers ──────────────────────────────────────────────────────────────────

func _shuffled_hand() -> Array[Card]:
	var pool: Array[Card] = []
	for c in _hand_manager.hand:
		pool.append(c)
	RNG.array_shuffle(pool)
	return pool
