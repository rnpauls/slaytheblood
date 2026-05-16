extends Card

const STUNNED_STATUS = preload("res://statuses/stunned.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_apply_stun
	on_hit.args = []
	on_hit.ai_value = ai_value
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_stun(atk_target: Node, _args: Array) -> void:
	if atk_target == null or atk_target.status_handler == null:
		return
	atk_target.status_handler.add_status(STUNNED_STATUS.duplicate())
