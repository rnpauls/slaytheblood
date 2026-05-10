## Cheap Marked payoff. Doubles the swing's base damage if the target is
## Marked — does NOT consume Marked, so it's the "snipe" complement to
## Executioner's "spend" pattern. Marked's own DMG_TAKEN bonus also applies
## on top of the doubled damage.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		return
	var damage := attack
	var target_node := targets[0]
	if target_node.status_handler and target_node.status_handler.has_status("marked"):
		damage = attack * 2
	do_stock_attack_damage_effect(targets, modifiers, damage)
