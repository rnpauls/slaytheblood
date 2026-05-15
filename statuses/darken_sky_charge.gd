## On-attack buff: the next attack the owner makes spawns N runechants on hit.
## Mirrors Poison Tip's lifecycle — attaches an OnHit to active_on_hits, ticks
## down on attack_completed and at turn-end, cleans up in _exit_tree.
##
## Stacks INTENSITY-style: applying twice before attacking doubles the runechants
## the next hit creates (handled via update() rebinding the captured stacks).
class_name DarkenSkyChargeStatus
extends Status

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")

var target_on_hits: Array[OnHit]

var _target_ref: Node = null
var _bound_apply: Callable


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	_target_ref = target
	_bound_apply = apply_status.bind(target)
	target_on_hits = target.active_on_hits

	var on_hit := OnHit.new()
	on_hit.id = "darken_sky_charge"
	on_hit.custom_func = _on_hit_create_runechants
	on_hit.args = [target.status_handler]
	on_hit.ai_value = stacks
	target_on_hits.append(on_hit)

	target.attack_completed.connect(_bound_apply)
	if target is Player:
		Events.player_turn_ended.connect(_bound_apply)
	else:
		Events.enemy_phase_ended.connect(_bound_apply)


func update() -> void:
	# Called by StatusHandler.add_status when stacks merge into an existing
	# instance. The OnHit reads `self.stacks` at fire time, so we only need
	# to refresh ai_value here for enemy targeting weight.
	if target_on_hits == null:
		return
	for h: OnHit in target_on_hits:
		if h.id == "darken_sky_charge":
			h.ai_value = stacks


func _exit_tree() -> void:
	if target_on_hits != null:
		var existing := target_on_hits.filter(
			func(h: OnHit) -> bool: return h.id == "darken_sky_charge"
		)
		for h in existing:
			target_on_hits.erase(h)
	if _bound_apply:
		if _target_ref is Player:
			if Events.player_turn_ended.is_connected(_bound_apply):
				Events.player_turn_ended.disconnect(_bound_apply)
		else:
			if Events.enemy_phase_ended.is_connected(_bound_apply):
				Events.enemy_phase_ended.disconnect(_bound_apply)


func _on_hit_create_runechants(_atk_target: Node, args: Array) -> void:
	if args.is_empty():
		return
	var status_handler := args[0] as StatusHandler
	if status_handler == null:
		return
	var rune := RUNECHANT_STATUS.duplicate()
	rune.stacks = stacks
	status_handler.add_status(rune)
