## Cantrip attack — light hit, on-hit draws a card. Keeps Ninja tempo flowing.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.id = "quick_reflexes_draw"
	on_hit.custom_func = _on_hit_draw_card
	on_hit.args = [modifiers] as Array[ModifierHandler]
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_draw_card(_atk_target: Node, args: Array[ModifierHandler]) -> void:
	var combatant := args[0].get_parent() as Combatant
	if combatant and combatant.hand_facade:
		combatant.hand_facade.draw_cards(1)
