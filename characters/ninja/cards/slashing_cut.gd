## Bleed applier. On hit: stack Bleed on target. The Bleed ticks at the
## target's end-of-turn for `bleed_stacks` damage per stack. Stack
## intensity merges across multiple Slashing Cuts.
extends Card

const BLEED_STATUS = preload("res://statuses/bleed.tres")

@export var bleed_stacks: int = 3


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.id = "slashing_cut_bleed"
	on_hit.custom_func = _on_hit_apply_bleed
	on_hit.args = [bleed_stacks]
	on_hit.ai_value = bleed_stacks
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_bleed(atk_target: Node, args: Array) -> void:
	if atk_target == null or atk_target.status_handler == null:
		return
	var bleed := BLEED_STATUS.duplicate()
	bleed.stacks = args[0]
	bleed.duration = 2
	atk_target.status_handler.add_status(bleed)
