## Captain's Strike: Warlord signature attack. Heavy single hit (6 atk for 2
## mana) that paints the player with Marked 2 — every other enemy in the
## encounter follows up for +2 damage on their next swings this turn. Plays
## hand-in-hand with War Cry / Warlord's Order.
extends Card

const MARKED_STATUS := preload("res://statuses/marked.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var hit := OnHit.new()
	hit.custom_func = _on_hit_apply_marked
	hit.ai_value = 5
	on_hits.append(hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_marked(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: MarkedStatus = MARKED_STATUS.duplicate()
		dup.stacks = 2
		dup.duration = 1
		sh.add_status(dup)
