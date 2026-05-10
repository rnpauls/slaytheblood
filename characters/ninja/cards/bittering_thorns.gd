extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit = OnHit.new()
	on_hit.custom_func = _on_hit_buff_next_attack
	on_hit.args = [modifiers] as Array[ModifierHandler]
	on_hit.ai_value = 1
	on_hits.append(on_hit)
	
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_buff_next_attack(atk_target: Node, args: Array[ModifierHandler]) -> void:
	if not atk_target: return

	var status_handler : StatusHandler = args[0].get_parent().status_handler
	#for status_ui: StatusUI in status_handler.get_children(): #Don't have a good way to remove status_ui by id
		#if status_ui.status.id == "empowered" and status_ui.status.duration < 2:
			#status_ui.queue_free()
	var old_emp_status = status_handler._get_status("empowered")
	if old_emp_status and old_emp_status.duration < 2:
		old_emp_status.set_duration(2)
		old_emp_status.set_stacks(1)
		return
	
	var empowered_status = preload("res://statuses/empowered.tres").duplicate()
	empowered_status.duration = 2
	empowered_status.stacks = 1
	status_handler.add_status(empowered_status)
