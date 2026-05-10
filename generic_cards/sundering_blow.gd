extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_destroy_equip
	on_hit.ai_value = 6
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_destroy_equip(atk_target: Node, _args: Array) -> void:
	if not (atk_target is Player):
		return
	var player := atk_target as Player
	if not player.stats or not player.stats.inventory:
		return
	var equips: Array = player.stats.inventory.equips
	if equips.is_empty():
		return
	var eq: Equipment = equips[randi() % equips.size()]
	if not eq or eq.unbreakable:
		return
	var ph := player.player_handler
	if ph:
		var handlers := [
			ph.equipment_head, ph.equipment_chest, ph.equipment_arms, ph.equipment_legs,
			ph.hand_left_equipment, ph.hand_right_equipment,
		]
		for h in handlers:
			if h and h.equipment == eq:
				h.call("_destroy_equipment")
				return
	# Fallback: equipment is in inventory but not bound to a handler slot.
	eq.on_destroyed(player)
	eq.deactivate_equipment(player)
	player.stats.inventory.remove_equipment(eq)
