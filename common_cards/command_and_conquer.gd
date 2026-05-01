extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(dealer: Node, target: Node) -> String:
	return tooltip_text % Hook.get_damage(dealer, target, attack)

func apply_effects(targets: Array[Node]) -> void:
	var on_hit:= OnHit.new()
	var cnc_effect := CncEffect.new()
	on_hit.effect = cnc_effect
	if targets[0].enemy_ai.arsenal:
		on_hit.ai_value = 3
	on_hits.append(on_hit)
	
	do_stock_attack_damage_effect(targets)
