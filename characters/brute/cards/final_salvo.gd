## Dynamic-cost AoE finisher. Cost drops by 1 per 2 cards the brute has
## discarded this combat (rampage / sixloot / pitch-into-discard all count).
## A long fight with lots of rampage churn can land Final Salvo for free
## as a closer; an early-fight play stays expensive.
extends Card

@export var discards_per_discount: int = 2


func get_play_cost() -> int:
	var discount := 0
	if owner and owner.stats and discards_per_discount > 0:
		discount = owner.stats.discards_this_combat / discards_per_discount
	return maxi(0, cost - discount)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
