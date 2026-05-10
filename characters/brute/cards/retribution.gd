## Hybrid attack/buff: swing for `attack` damage and load up Thorns for the
## rest of the turn. Pairs the offensive and defensive halves of the Bulwark
## build into one card.
extends Card

const THORNS_STATUS = preload("res://statuses/thorns.tres")

@export var thorns_stacks: int = 3


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
	if owner and owner.status_handler:
		var thorns := THORNS_STATUS.duplicate()
		thorns.stacks = thorns_stacks
		thorns.duration = 1
		owner.status_handler.add_status(thorns)
