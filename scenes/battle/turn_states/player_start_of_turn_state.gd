# Replaces the implicit "enemy_phase_ended → player_handler.start_turn"
# connect that used to live in Battle._ready (line 22 pre-refactor).
#
# enter() kicks the existing START_OF_TURN cascade by calling
# player_handler.start_turn(). That cascade emits
# Events.player_action_phase_started when statuses finish applying;
# we listen for that and transition to PLAYER_ACTION.
class_name PlayerStartOfTurnState
extends TurnState


func enter() -> void:
	if _is_stalemate():
		Events.battle_over_screen_requested.emit("Stalemate!", BattleOverPanel.Type.STALEMATE)
		_request(State.STALEMATE)
		return
	Events.player_action_phase_started.connect(_on_action_phase_started)
	_arm_watchdog(State.PLAYER_ACTION)
	player_handler.start_turn()


func exit() -> void:
	if Events.player_action_phase_started.is_connected(_on_action_phase_started):
		Events.player_action_phase_started.disconnect(_on_action_phase_started)
	_disarm_watchdog()


func _on_action_phase_started() -> void:
	_request(State.PLAYER_ACTION)


# Stalemate fires when neither side can draw or play another card. Each side
# is "stuck" only when hand AND draw pile AND discard pile are all empty —
# discard is part of the check because an empty draw pile auto-recycles from
# the discard (no shuffle) on the next draw. Exhaust pile is NOT part of the
# check: exhausted cards never come back.
func _is_stalemate() -> bool:
	if player_handler.hand.get_child_count() > 0:
		return false
	if not player_handler.character.draw_pile.empty():
		return false
	if not player_handler.character.discard.empty():
		return false
	if _player_has_zero_cost_weapon():
		return false

	var enemy_count := 0
	var all_enemies_bleeding := true
	for enemy in enemy_handler.get_children():
		if not is_instance_valid(enemy):
			continue
		if not enemy.hand_manager.hand.is_empty():
			return false
		if not enemy.stats.draw_pile.empty():
			return false
		if not enemy.stats.discard.empty():
			return false
		enemy_count += 1
		if not enemy.status_handler.has_status("bleed"):
			all_enemies_bleeding = false

	# Bleed will tick down every enemy at end-of-turn until VICTORY fires —
	# only skip the stalemate when the player isn't also bleeding out.
	if enemy_count > 0 and all_enemies_bleeding \
			and not player_handler.character.status_handler.has_status("bleed"):
		return false
	return true


func _player_has_zero_cost_weapon() -> bool:
	for wep in [player_handler.hand_left_weapon, player_handler.hand_right_weapon] as Array[WeaponHandler]:
		if wep and wep.weapon and wep.weapon.cost == 0:
			return true
	return false
