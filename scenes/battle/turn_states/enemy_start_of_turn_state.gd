# Per-enemy SOT. Picks the next acting enemy and runs its SOT statuses
# → AI plan cascade.
#
# Re-entered from ENEMY_EOT (next enemy) and from ENEMY_ACTING when
# the current enemy dies mid-action (skip to next without applying
# EOT statuses on a corpse).
#
# Entry preconditions: PLAYER_EOT.enter() called enemy_handler.start_turn()
# which populated acting_enemies. We pick acting_enemies[0] each entry.
class_name EnemyStartOfTurnState
extends TurnState

var _current_enemy: Enemy


func enter() -> void:
	# First entry of the phase (from PLAYER_EOT) — populate acting_enemies.
	# Re-entry already has them.
	if enemy_handler.acting_enemies.is_empty() and enemy_handler.get_child_count() > 0:
		enemy_handler.start_turn()

	# Defensive: nothing to do if no enemies remain. Normally
	# _on_enemies_child_order_changed will have already forced VICTORY
	# before we got here, but handle it gracefully either way.
	if enemy_handler.acting_enemies.is_empty():
		_request.call_deferred(State.PLAYER_SOT)
		return

	_current_enemy = enemy_handler.acting_enemies[0]

	# Skip current_enemy if it died between phases (paranoia — EnemyHandler
	# should have already removed dead enemies from acting_enemies).
	if not is_instance_valid(_current_enemy):
		enemy_handler.acting_enemies.pop_front()
		_request.call_deferred(State.ENEMY_SOT)
		return

	Events.enemy_died.connect(_on_enemy_died)
	_current_enemy.status_handler.statuses_applied.connect(_on_statuses_applied)
	_current_enemy.enemy_ai.plan_created.connect(_on_plan_created)
	_arm_watchdog(State.ENEMY_ACTING)

	# Wait for the TURN announcement to finish before kicking off the SOT
	# cascade — player needs time to read who's acting. BattleUI emits
	# turn_announcement_finished at the end of its tween chain (or
	# immediately on re-entry edge cases where no announcement plays — see
	# bail-outs above, which return before reaching this line).
	Events.turn_announcement_finished.connect(_start_sot_cascade, CONNECT_ONE_SHOT)


func _start_sot_cascade() -> void:
	# Defensive: the state may have already moved on (e.g. enemy died via DOT
	# during the announcement). Bail rather than poking statuses on a corpse.
	if not is_instance_valid(_current_enemy):
		return
	_current_enemy.status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)


func exit() -> void:
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)
	if Events.turn_announcement_finished.is_connected(_start_sot_cascade):
		Events.turn_announcement_finished.disconnect(_start_sot_cascade)
	if _current_enemy and is_instance_valid(_current_enemy):
		var sh := _current_enemy.status_handler
		if sh and sh.statuses_applied.is_connected(_on_statuses_applied):
			sh.statuses_applied.disconnect(_on_statuses_applied)
		var ai := _current_enemy.enemy_ai
		if ai and ai.plan_created.is_connected(_on_plan_created):
			ai.plan_created.disconnect(_on_plan_created)
	_disarm_watchdog()


func _on_enemy_died(enemy: Enemy) -> void:
	# If the enemy whose SOT we're running just died (e.g. lingering DOT
	# from prior turn finished it off), skip ahead. EnemyHandler has
	# already removed it from acting_enemies via its own _on_enemy_died.
	if enemy == _current_enemy:
		_request(State.ENEMY_SOT)


func _on_statuses_applied(type: Status.Type) -> void:
	if type != Status.Type.START_OF_TURN:
		return
	# AI builds turn plan; emits plan_created when done.
	_current_enemy.enemy_ai.start_turn(battle.player.stats.health)


func _on_plan_created(_enemy: Enemy) -> void:
	_request(State.ENEMY_ACTING)
