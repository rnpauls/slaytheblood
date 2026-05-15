## Unblockable: the bearer's next attack ignores the target's block entirely.
##
## Lifecycle:
##   - Applied via on-hit of an attack (e.g. Telegraph Strike). Starts `fresh = true`.
##   - At end of bearer's phase, `fresh` flips to false. The status survives the
##     turn boundary so the player can see the telegraph in the enemy's status row.
##   - Next time the bearer builds an attack packet AND status is not fresh, the
##     packet is marked ignore_block. Consumed (stacks - 1) when the attack lands.
##
## INTENSITY stacking lets multiple Telegraph Strikes pile up — each grants one
## unblockable swing. stacks=0 → StatusUI auto-frees.
##
## type=EVENT_BASED so apply_statuses_by_type doesn't auto-fire it; we drive
## the fresh-flip ourselves off the phase-end signals.
class_name UnblockableStatus
extends Status

## True for the turn the status was applied; flips to false at the end of the
## bearer's phase. Attacks only ignore block when fresh is false — preventing a
## same-turn apply-and-use chain.
var fresh: bool = true

var _target_ref: Node = null


func get_tooltip() -> String:
	if fresh:
		return tooltip + " (telegraphed — fires next turn)"
	return tooltip


func initialize_status(target: Node) -> void:
	_target_ref = target
	if target is Player:
		Events.player_turn_ended.connect(_on_phase_ended)
	else:
		Events.enemy_phase_ended.connect(_on_phase_ended)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func update() -> void:
	# When stacked from another Telegraph Strike, the new application is also
	# fresh — the player should see the telegraph for both copies.
	fresh = true


## Consume one stack after an unblockable swing lands. stacks=0 frees the
## StatusUI (handled by StatusUI._on_status_changed).
func consume() -> void:
	stacks = maxi(0, stacks - 1)


func _on_phase_ended() -> void:
	if fresh:
		fresh = false
		# Force a UI refresh — fresh isn't a tracked field on the StatusUI, so
		# we nudge status_changed to trigger any listeners (tooltip refresh, etc.).
		status_changed.emit()


func _exit_tree() -> void:
	if _target_ref is Player:
		if Events.player_turn_ended.is_connected(_on_phase_ended):
			Events.player_turn_ended.disconnect(_on_phase_ended)
	else:
		if Events.enemy_phase_ended.is_connected(_on_phase_ended):
			Events.enemy_phase_ended.disconnect(_on_phase_ended)
