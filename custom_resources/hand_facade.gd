## Symmetric hand-operation interface for effects. Both Player and Enemy
## extend Combatant; each combatant owns a concrete HandFacade subclass
## (PlayerHandFacade, EnemyHandFacade) that absorbs the asymmetry between
## the player's UI-driven hand (PlayerCardUI children of Hand) and the
## enemy's data-driven hand (EnemyHandManager.hand: Array[Card]).
##
## Effects targeting a Combatant call:
##   target.hand_facade.discard_random(n)
##   target.hand_facade.exhaust_random(n)
##   target.hand_facade.destroy_arsenal()
##   target.hand_facade.draw_cards(n)
## …without branching on `target is Player` vs `target is Enemy`.
##
## Method semantics:
##   * `n` is silently capped at the current hand size.
##   * Mutating methods return the array of cards actually affected, so
##     callers can inspect (e.g. DiscardRandomSixEffect needs to know whether
##     all chosen cards passed its filter).
class_name HandFacade
extends RefCounted

# ── Queries ───────────────────────────────────────────────────────────────────

## Snapshot of cards in the current hand. Subclasses MUST return a fresh array
## (not the underlying mutable storage) so callers can safely modify it.
func get_hand() -> Array[Card]:
	return []

func size() -> int:
	return 0

func is_intimidated(_card: Card) -> bool:
	return false

func has_arsenal() -> bool:
	return false


# ── Mutations ────────────────────────────────────────────────────────────────

## Pick `n` random cards from the hand and discard them. Returns the actually
## discarded cards (may be fewer than `n` if hand is small).
func discard_random(_n: int) -> Array[Card]:
	push_warning("HandFacade.discard_random called on base class")
	return []

## Like discard_random but only chooses from cards matching `predicate(card)`.
## Returns the actually discarded cards.
func discard_random_filtered(_predicate: Callable, _n: int) -> Array[Card]:
	push_warning("HandFacade.discard_random_filtered called on base class")
	return []

## Pick `n` random cards from the hand and remove them WITHOUT going to discard
## (one-shot exhaust). Returns the actually exhausted cards.
func exhaust_random(_n: int) -> Array[Card]:
	push_warning("HandFacade.exhaust_random called on base class")
	return []

## Draw `n` cards from the draw pile. Returns the Tween driving the staggered
## draws (may be null for instant cases).
func draw_cards(_n: int) -> Tween:
	push_warning("HandFacade.draw_cards called on base class")
	return null

## Move every card in the discard pile back to the draw pile and shuffle.
func reshuffle_discard() -> void:
	push_warning("HandFacade.reshuffle_discard called on base class")

## Destroy the arsenal slot card. Returns true if there was one to destroy.
func destroy_arsenal() -> bool:
	return false
