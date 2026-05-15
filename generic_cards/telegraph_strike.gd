## Telegraph Strike: applies Unblockable to the wielder on hit. Per the
## status spec, the freshly-applied stack flips to "armed" only at end of
## the wielder's phase — so the player sees an Unblockable badge appear,
## survives the player turn, and on the wielder's next turn the wielder's
## first attack ignores block entirely. NOT go-again, by design — chaining
## the apply with another swing on the same turn would defeat the telegraph.
extends Card

const UNBLOCKABLE_STATUS := preload("res://statuses/unblockable.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var hit := OnHit.new()
	hit.id = "telegraph_strike_apply_unblockable"
	hit.custom_func = _on_hit_apply_unblockable
	hit.ai_value = 6
	on_hits.append(hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_unblockable(_atk_target: Node, _args: Array) -> void:
	if owner == null or owner.status_handler == null:
		return
	var dup: UnblockableStatus = UNBLOCKABLE_STATUS.duplicate()
	dup.stacks = 1
	dup.fresh = true
	owner.status_handler.add_status(dup)
