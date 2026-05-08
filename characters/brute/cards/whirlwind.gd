extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var alive_targets := targets.filter(func(t):
		return is_instance_valid(t) and t is Enemy and t.stats.health > 0)
	go_again = alive_targets.size() >= 2
	do_stock_attack_damage_effect(targets, modifiers)
