## Cantrip attack — both the physical hit and the zap can independently fire
## the on-hit draw, so a clean play against an unprepared target draws 2 cards
## (one per landing component).
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.id = "aether_conduit_draw"
	on_hit.custom_func = _on_hit_draw_card
	on_hit.args = [modifiers] as Array[ModifierHandler]
	on_hit.ai_value = 2
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_draw_card(_atk_target: Node, args: Array[ModifierHandler]) -> void:
	var combatant := args[0].get_parent() as Combatant
	if combatant and combatant.hand_facade:
		combatant.hand_facade.draw_cards(1)
