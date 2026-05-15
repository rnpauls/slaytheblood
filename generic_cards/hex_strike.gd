## Hex Strike: multi-debuff on-hit attack pairing Exposed (50% dmg taken next
## turn) with Marked (+1 dmg this turn). The cocktail makes the next attack
## from any source meaningfully bigger.
extends Card

const EXPOSED_STATUS := preload("res://statuses/exposed.tres")
const MARKED_STATUS := preload("res://statuses/marked.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var exposed_hit := OnHit.new()
	exposed_hit.custom_func = _on_hit_apply_exposed
	exposed_hit.ai_value = 4
	on_hits.append(exposed_hit)

	var marked_hit := OnHit.new()
	marked_hit.custom_func = _on_hit_apply_marked
	marked_hit.ai_value = 3
	on_hits.append(marked_hit)

	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_exposed(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: Status = EXPOSED_STATUS.duplicate()
		dup.duration = 1
		dup.stacks = 1
		sh.add_status(dup)


func _on_hit_apply_marked(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: MarkedStatus = MARKED_STATUS.duplicate()
		dup.duration = 1
		dup.stacks = 1
		sh.add_status(dup)
