## Discard-payoff card. When this gets discarded (rampage/sixloot, random
## discard from enemy effects, etc.), the brute gains a mana. Designed to
## be a sixloot-preferred target — attack 6 means sixloot's >5 filter picks
## this first when chaining rampage cards. Pitching it gives 1 mana up front
## and skips the play+discard loop, so the discard payoff is the consolation
## prize when rampage forces it out of hand.
extends Card

@export var mana_on_discard: int = 1


func discard_card() -> void:
	if owner and owner.stats:
		owner.stats.mana += mana_on_discard
	super.discard_card()
