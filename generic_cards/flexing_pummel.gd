extends Card

const MUSCLE_STATUS := preload("res://statuses/muscle.tres")

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_self_muscle
	on_hit.ai_value = 4
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_self_muscle(_atk_target: Node, _args: Array) -> void:
	if not owner or not owner.status_handler:
		return
	var dup: MuscleStatus = MUSCLE_STATUS.duplicate()
	dup.stacks = 1
	owner.status_handler.add_status(dup)
