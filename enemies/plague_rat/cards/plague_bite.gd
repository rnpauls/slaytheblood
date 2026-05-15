## Plague Bite: Plague Rat attack that piles +damage onto the player for the
## current turn. Marked is the closest existing status to "incoming-damage
## debuff" — applied to the player, every subsequent hit lands harder, which
## scales nicely when paired with another rat or a Plague Doctor.
extends Card

const MARKED_STATUS := preload("res://statuses/marked.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_apply_marked
	on_hit.ai_value = 3
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_marked(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: MarkedStatus = MARKED_STATUS.duplicate()
		dup.stacks = 1
		dup.duration = 1
		sh.add_status(dup)
