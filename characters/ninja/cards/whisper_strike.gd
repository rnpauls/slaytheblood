extends Card

const POISON_TIP_STATUS = preload("res://statuses/poison_tip.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_apply_poison_tip
	on_hit.args = [modifiers] as Array[ModifierHandler]
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_poison_tip(_atk_target: Node, args: Array[ModifierHandler]) -> void:
	var status_handler: StatusHandler = args[0].get_parent().status_handler
	var poison_tip := POISON_TIP_STATUS.duplicate()
	poison_tip.stacks = 2
	status_handler.add_status(poison_tip)
