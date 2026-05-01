extends Card

func get_updated_tooltip(dealer: Node, target: Node) -> String:
	return tooltip_text % Hook.get_damage(dealer, target, attack)

func apply_effects(targets: Array[Node]) -> void:
	var on_hit:= OnHit.new()
	var discard_eff:= DiscardRandomEffect.new()
	discard_eff.amount = 1
	on_hit.effect=discard_eff
	on_hit.ai_value = 3
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets)

	
