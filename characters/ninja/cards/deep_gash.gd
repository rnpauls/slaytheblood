## Bleed applier. On hit: apply Bleed of duration `bleed_duration` to target.
## DURATION-stacked: extends the bleed timer on top of any existing Bleed.
extends Card

const BLEED_STATUS = preload("res://statuses/bleed.tres")

@export var bleed_duration: int = 3


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.id = "deep_gash_bleed"
	on_hit.custom_func = _on_hit_apply_bleed
	on_hit.args = [bleed_duration]
	on_hit.ai_value = bleed_duration
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_bleed(atk_target: Node, args: Array) -> void:
	if atk_target == null or atk_target.status_handler == null:
		return
	var bleed := BLEED_STATUS.duplicate()
	bleed.duration = args[0]
	atk_target.status_handler.add_status(bleed)
