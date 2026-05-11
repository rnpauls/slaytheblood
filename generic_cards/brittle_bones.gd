extends Card

const BRITTLE_STATUS := preload("res://statuses/brittle.tres")

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_apply_brittle
	on_hit.ai_value = 5
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_apply_brittle(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: BrittleStatus = BRITTLE_STATUS.duplicate()
		dup.stacks = 2
		sh.add_status(dup)
