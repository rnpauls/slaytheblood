extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	var exhaust := ExhaustRandomEffect.new()
	exhaust.amount = 1
	on_hit.effect = exhaust
	on_hit.ai_value = 4
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)
