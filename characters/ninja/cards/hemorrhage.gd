## Bleed payoff. Deals base damage plus extra equal to target's current
## Bleed duration. Does NOT consume Bleed — the DoT continues ticking — so
## this is a burst-on-top, not a Bleed spend. Pairs with Deep Gash /
## Razor Edge to amplify a built-up Bleed pile.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		do_stock_attack_damage_effect(targets, modifiers)
		return
	var target_node := targets[0]
	var bonus := 0
	if target_node.status_handler:
		var bleed: Status = target_node.status_handler.get_status_by_id("bleed")
		if bleed:
			bonus = bleed.duration
	do_stock_attack_damage_effect(targets, modifiers, attack + bonus)
