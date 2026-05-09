extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit:= OnHit.new()
	var cnc_effect := CncEffect.new()
	on_hit.effect = cnc_effect
	if targets[0].enemy_ai.arsenal:
		on_hit.ai_value = 3
	on_hits.append(on_hit)
	
	do_stock_attack_damage_effect(targets, modifiers)
