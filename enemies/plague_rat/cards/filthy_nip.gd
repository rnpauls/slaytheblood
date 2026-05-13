extends Card

const POISON_TIP_STATUS := preload("res://statuses/poison_tip.tres")

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_apply_poison_tip
	on_hit.ai_value = 3
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_apply_poison_tip(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: PoisonTipStatus = POISON_TIP_STATUS.duplicate()
		dup.stacks = 3
		dup.duration = 1
		sh.add_status(dup)
