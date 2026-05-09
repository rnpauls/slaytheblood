extends Card

# Bloodlust: standard hit + applies a permanent stack of Muscle to the wielder
# (not temporary — Reaver scales as the fight drags on).

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
	if owner and owner.status_handler:
		var muscle: MuscleStatus = preload("res://statuses/muscle.tres").duplicate()
		muscle.stacks = 1
		owner.status_handler.add_status(muscle)
