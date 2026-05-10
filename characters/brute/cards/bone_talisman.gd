## Discard-payoff sibling to War Trophy: when this hits the discard pile
## (rampage / sixloot / forced discard), the brute draws a card. attack 6
## means sixloot's >5 filter prefers it, so rampage chains naturally cycle
## this through hand → discard → draw → next play.
extends Card

@export var cards_on_discard: int = 1


func discard_card() -> void:
	if owner and owner.hand_facade and cards_on_discard > 0:
		owner.hand_facade.draw_cards(cards_on_discard)
	super.discard_card()
