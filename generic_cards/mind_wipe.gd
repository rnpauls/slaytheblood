extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_mind_wipe
	on_hit.ai_value = 6
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_mind_wipe(atk_target: Node, _args: Array) -> void:
	if not (atk_target is Combatant):
		return
	var combatant := atk_target as Combatant
	if not combatant.hand_facade:
		return
	var hand_size: int = combatant.hand_facade.size()
	if hand_size <= 0:
		return
	combatant.hand_facade.discard_random(hand_size)
	var redraw := hand_size - 1
	if redraw > 0:
		combatant.hand_facade.draw_cards(redraw)
