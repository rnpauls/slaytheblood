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
# check: exhausted cards never come back. An enemy with a playable arsenal
# (an attack it can afford) is also not stuck.
func _is_stalemate() -> bool:
	if player_handler.hand.get_child_count() > 0:
		return false
	if not player_handler.character.draw_pile.empty():
		return false
	if not player_handler.character.discard.empty():
		return false

	for enemy in enemy_handler.get_children():
		if not is_instance_valid(enemy):
			continue
		if not enemy.hand_manager.hand.is_empty():
			return false
		if not enemy.stats.draw_pile.empty():
			return false
		if not enemy.stats.discard.empty():
			return false
		if _has_playable_arsenal(enemy):
			return false
	return true


func _has_playable_arsenal(enemy: Enemy) -> bool:
	if enemy.enemy_ai == null or enemy.enemy_ai.arsenal == null:
		return false
	var arsenal: Card = enemy.enemy_ai.arsenal
	return arsenal.type == Card.Type.ATTACK and arsenal.cost <= enemy.stats.mana
