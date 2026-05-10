## Dynamic-cost attack. Cost drops by 1 per attack the ninja has already
## declared this turn (capped at 0). Plays into a tempo curve: a turn that
## opens with a couple of small attacks lets Cascade Strike land for free.
##
## The ordering in card.gd:play() — pay mana, then emit player_attack_declared
## — means Cascade Strike does NOT self-discount: its own attack won't bump
## the counter until after its cost is locked in.
extends Card


func get_play_cost() -> int:
	var discount := 0
	if owner and owner.stats:
		discount = owner.stats.attacks_this_turn
	return maxi(0, cost - discount)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
