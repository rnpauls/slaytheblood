## Distribute Toxin: Plague Doctor buff card. Applies Poison Tip 2 to every
## allied enemy — their next attack lands extra arcane-style on-hit damage
## (Poison Tip puts a damage on-hit on the target's `active_on_hits`). The
## Doctor herself benefits too, but the real payoff is in multi-enemy fights
## where 2-3 rats all toxin-tip your face on their next swing.
extends Card

const POISON_TIP_STATUS := preload("res://statuses/poison_tip.tres")
const POISON_STACKS := 2


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if not (n is Combatant and n.stats and n.stats.health > 0 and n.status_handler):
			continue
		var dup: PoisonTipStatus = POISON_TIP_STATUS.duplicate()
		dup.stacks = POISON_STACKS
		dup.duration = 1
		n.status_handler.add_status(dup)
