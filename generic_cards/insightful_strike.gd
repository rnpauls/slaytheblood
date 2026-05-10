extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_draw_card
	on_hit.ai_value = 3
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_draw_card(_atk_target: Node, _args: Array) -> void:
	if owner and owner.hand_facade:
		owner.hand_facade.draw_cards(1)
