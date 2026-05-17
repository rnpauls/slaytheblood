# Per-enemy EOT. Owns the EOT cascade for the current enemy and decides
# whether to loop back to ENEMY_SOT for another enemy or hand off to
# PLAYER_SOT.
#
# Reached only when the action loop exited normally (plan exhausted).
# If the current enemy died, ENEMY_ACTING routes directly to ENEMY_SOT
# instead — no EOT statuses on a corpse.
class_name EnemyEndOfTurnState
extends TurnState

var _current_enemy: Enemy


func enter() -> void:
	if enemy_handler.acting_enemies.is_empty():
		_finish_phase()
		return

	_current_enemy = enemy_handler.acting_enemies[0]
	if not is_instance_valid(_current_enemy):
		# Defensive: somehow we got here with a dead enemy at the head.
		# Pop it and move on.
		enemy_handler.acting_enemies.pop_front()
		_advance.call_deferred()
		return

	_current_enemy.status_handler.statuses_applied.connect(_on_statuses_applied)
	# Worst-case fallback: force PLAYER_SOT, conceding any remaining enemies'
	# turns. Better than deadlocking on a missed statuses_applied signal.
	_arm_watchdog(State.PLAYER_SOT)
	_current_enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func exit() -> void:
	if _current_enemy and is_instance_valid(_current_enemy):
		var sh := _current_enemy.status_handler
		if sh and sh.statuses_applied.is_connected(_on_statuses_applied):
			sh.statuses_applied.disconnect(_on_statuses_applied)
	_disarm_watchdog()


func _on_statuses_applied(type: Status.Type) -> void:
	if type != Status.Type.END_OF_TURN:
		return
	if _current_enemy and is_instance_valid(_current_enemy):
		await _current_enemy.exhaust_fleeting_in_hand()
	enemy_handler.acting_enemies.erase(_current_enemy)
	_advance()


func _advance() -> void:
	if enemy_handler.acting_enemies.is_empty():
		_finish_phase()
	else:
		_request(State.ENEMY_SOT)


# Tail of the enemy phase. Calls into enemy_handler.enemy_end_phase()
# so the per-enemy cleanup_phase() hooks still run, then emits the
# legacy enemy_phase_ended signal (BattleUI listens for it to reset
# the END button text). Then transitions to PLAYER_SOT — unless every
# alive enemy is fatigued (no cards anywhere + no 0-cost weapon), in
# which case the player auto-wins via FATIGUE_VICTORY.
func _finish_phase() -> void:
	enemy_handler.enemy_end_phase()
	if _all_alive_enemies_fatigued():
		_request(State.FATIGUE_VICTORY)
	else:
		_request(State.PLAYER_SOT)


func _all_alive_enemies_fatigued() -> bool:
	var any := false
	for child in enemy_handler.get_children():
		if not (child is Enemy):
			continue
		var e := child as Enemy
		if not is_instance_valid(e) or e.stats == null or e.stats.health <= 0:
			continue
		any = true
		if not _is_fatigued(e):
			return false
	return any


func _is_fatigued(e: Enemy) -> bool:
	var no_cards := e.hand_manager.hand.is_empty() \
		and e.stats.draw_pile.empty() \
		and e.stats.discard.empty()
	var has_zero_cost_weapon := e.stats.hand_left is Weapon \
		and (e.stats.hand_left as Weapon).cost == 0
	return no_cards and not has_zero_cost_weapon
