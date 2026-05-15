## Shadowstep: Stalker NAA. Stalks one of the player's cards in hand and
## locks it for the upcoming player turn — can't be played, pitched, or used
## to block. Mostly hand denial; combined with Telegraph Strike's Unblockable
## the next round, the Stalker turns "stall me out with block" into a real
## resource squeeze.
##
## Inert is stack-aware: multiple Shadowsteps in the same enemy turn lock
## multiple cards. Status expires at end of the player's next turn.
extends Card

const INERT_CARD_STATUS := preload("res://statuses/inert_card.tres")


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	for t in targets:
		var sh: StatusHandler = t.get("status_handler") if t else null
		if sh == null:
			continue
		var dup: InertCardStatus = INERT_CARD_STATUS.duplicate()
		dup.stacks = 1
		dup.duration = 1
		sh.add_status(dup)
