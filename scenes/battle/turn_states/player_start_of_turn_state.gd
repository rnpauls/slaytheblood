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
	player_handler.start_turn()


func exit() -> void:
	if Events.player_action_phase_started.is_connected(_on_action_phase_started):
		Events.player_action_phase_started.disconnect(_on_action_phase_started)


func _on_action_phase_started() -> void:
	_request(State.PLAYER_ACTION)


# Stalemate fires when neither side can take a meaningful action: the
# player has no cards in hand or draw pile, and every alive enemy has
# no cards in hand, no draw pile, and no playable arsenal (a BLOCK or
# NAA arsenal — or an attack the enemy can't afford — doesn't count).
# Discard piles are intentionally not part of the check.
func _is_stalemate() -> bool:
	if player_handler.hand.get_child_count() > 0:
		return false
	if not player_handler.character.draw_pile.empty():
		return false

	for enemy in enemy_handler.get_children():
		if not is_instance_valid(enemy):
			continue
		if not enemy.hand_manager.hand.is_empty():
			return false
		if not enemy.stats.draw_pile.empty():
			return false
		if _has_playable_arsenal(enemy):
			return false
	return true


func _has_playable_arsenal(enemy: Enemy) -> bool:
	if enemy.enemy_ai == null or enemy.enemy_ai.arsenal == null:
		return false
	var arsenal: Card = enemy.enemy_ai.arsenal
	return arsenal.type == Card.Type.ATTACK and arsenal.cost <= enemy.stats.mana
