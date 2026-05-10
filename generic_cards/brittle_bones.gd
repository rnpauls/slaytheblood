extends Card

const FRAIL_STATUS := preload("res://statuses/frail.tres")

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_apply_frail
	on_hit.ai_value = 5
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_apply_frail(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: FrailStatus = FRAIL_STATUS.duplicate()
		dup.duration = 2
		sh.add_status(dup)
