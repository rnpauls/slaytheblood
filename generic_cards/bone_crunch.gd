## Bone Crunch: cheap multi-effect on-hit attack. Stacks Brittle 1 and Bleed 1
## per landing — a small, predictable status combo that pairs with any
## follow-up hit (Brittle weakens block, Bleed ticks at end of turn).
##
## Mirrors the Lance Boil pattern (two on-hit handlers, both fire on landing).
extends Card

const BRITTLE_STATUS := preload("res://statuses/brittle.tres")
const BLEED_STATUS := preload("res://statuses/bleed.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var brittle_hit := OnHit.new()
	brittle_hit.custom_func = _on_hit_apply_brittle
	brittle_hit.ai_value = 3
	on_hits.append(brittle_hit)

	var bleed_hit := OnHit.new()
	bleed_hit.custom_func = _on_hit_apply_bleed
	bleed_hit.ai_value = 2
	on_hits.append(bleed_hit)

	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_brittle(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: BrittleStatus = BRITTLE_STATUS.duplicate()
		dup.duration = 1
		sh.add_status(dup)


func _on_hit_apply_bleed(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: BleedStatus = BLEED_STATUS.duplicate()
		dup.duration = 1
		sh.add_status(dup)
