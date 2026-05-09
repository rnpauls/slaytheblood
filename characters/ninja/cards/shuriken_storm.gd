## AoE 1-damage attack that draws a card per enemy hit. Because on-hit
## effects fire once per damaged target (see attack_damage_effect.gd), one
## OnHit suffices — it triggers once per enemy with damage_dealt > 0.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.id = "shuriken_storm_draw"
	on_hit.custom_func = _on_hit_draw_card
	on_hit.args = [modifiers] as Array[ModifierHandler]
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_draw_card(_atk_target: Node, args: Array[ModifierHandler]) -> void:
	var combatant := args[0].get_parent() as Combatant
	if combatant and combatant.hand_facade:
		combatant.hand_facade.draw_cards(1)
