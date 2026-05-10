extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_heal_self
	on_hit.ai_value = 4
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_heal_self(_atk_target: Node, _args: Array) -> void:
	if owner and owner.stats:
		owner.stats.heal(3)
