## Multi-hit Bleed re-applier. Hits twice; the on-hit fires once per landed
## hit (per attack_damage_effect.gd's per-target loop), so a clean play
## stacks 2 Bleed on the target. Cheap way to maintain a Bleed pile while
## still putting damage on the board.
extends Card

const BLEED_STATUS = preload("res://statuses/bleed.tres")

@export var bleed_per_hit: int = 1


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.id = "razor_edge_bleed"
	on_hit.custom_func = _on_hit_apply_bleed
	on_hit.args = [bleed_per_hit]
	on_hit.ai_value = bleed_per_hit
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_bleed(atk_target: Node, args: Array) -> void:
	if atk_target == null or atk_target.status_handler == null:
		return
	var bleed := BLEED_STATUS.duplicate()
	bleed.stacks = args[0]
	bleed.duration = 2
	atk_target.status_handler.add_status(bleed)
