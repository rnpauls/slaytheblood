extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_grant_ap
	on_hit.args = [modifiers] as Array[ModifierHandler]
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_grant_ap(_atk_target: Node, args: Array[ModifierHandler]) -> void:
	var player := args[0].get_parent()
	player.stats.action_points += 1
