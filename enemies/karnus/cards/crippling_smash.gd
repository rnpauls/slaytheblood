## Crippling Smash: Karnus signature. Heavy 6-cost, 10-attack swing that
## also lands Crippled 2 — the player's outgoing attacks deal -2 dmg this
## turn, then -1 next turn before ticking off. Combined with Karnus's high
## HP, this turns "kill him fast" into "kill him fast while he tanks you and
## you hit weaker for two turns."
extends Card

const CRIPPLED_STATUS := preload("res://statuses/crippled.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var hit := OnHit.new()
	hit.custom_func = _on_hit_apply_crippled
	hit.ai_value = 8
	on_hits.append(hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_apply_crippled(atk_target: Node, _args: Array) -> void:
	var sh: StatusHandler = atk_target.get("status_handler")
	if sh:
		var dup: CrippledStatus = CRIPPLED_STATUS.duplicate()
		dup.duration = 2
		sh.add_status(dup)
