extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_stock_attack_damage_effect(targets, modifiers)
	do_stock_attack_damage_effect(targets, modifiers)
