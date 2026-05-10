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


# ── Interactive prompts ──────────────────────────────────────────────────────

## Ask the owning combatant to pick `count` cards from its hand. Awaitable.
## For Player: shows the choose-cards UI and waits for the click. For Enemy:
## random pick (no UI). Optional prompt_text customizes the label shown to
## the player ("Sink a card", "Exhaust a card", etc.); ignored on enemy side.
##
## Returns the actually chosen cards (may be fewer than `count` if hand size
## is smaller, or empty if the prompt is cancelled).
func prompt_choose_cards(_count: int, _prompt_text: String = "") -> Array[Card]:
	push_warning("HandFacade.prompt_choose_cards called on base class")
	return []


# ── Per-card operations (operate on a specific Card already in hand) ─────────

## Sink the given card from hand back into the draw pile. Player side flies
## the visual to the draw pile and routes through card.sink_card; enemy side
## adds the card to enemy stats.draw_pile and removes from hand.
func sink_card(_card: Card) -> void:
	push_warning("HandFacade.sink_card called on base class")

## Discard the given card. Player side flies the visual through CardUI.discard
## (which fires Events.card_discarded → side effects like Enraged). Enemy
## side calls card.discard_card (puts it in enemy stats.discard) + removes
## from hand.
func discard_card(_card: Card) -> void:
	push_warning("HandFacade.discard_card called on base class")

## Exhaust the given card — remove from hand without going to discard. Player
## side queue_frees the visual; enemy side just removes from hand. (Neither
## side adds to a permanent exhaust pile in this method — match existing
## ExhaustRandomEffect semantics.)
func exhaust_card(_card: Card) -> void:
	push_warning("HandFacade.exhaust_card called on base class")
