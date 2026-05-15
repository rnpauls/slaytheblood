extends Card

const BLEED_STATUS := preload("res://statuses/bleed.tres")
const POISON_TIP_STATUS := preload("res://statuses/poison_tip.tres")

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var bleed_hit := OnHit.new()
	bleed_hit.custom_func = _on_hit_apply_bleed
	bleed_hit.ai_value = 4
	on_hits.append(bleed_hit)

	var poison_hit := OnHit.new()
	poison_hit.custom_func = _on_hit_apply_poison_tip
	poison_hit.ai_value = 3
	on_hits.append(poison_hit)

	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_apply_bleed(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: BleedStatus = BLEED_STATUS.duplicate()
		dup.duration = 2
		sh.add_status(dup)

func _on_hit_apply_poison_tip(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: PoisonTipStatus = POISON_TIP_STATUS.duplicate()
		dup.stacks = 1
		dup.duration = 1
		sh.add_status(dup)
