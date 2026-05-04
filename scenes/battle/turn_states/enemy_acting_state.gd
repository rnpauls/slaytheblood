# Pass 1 scope: this state covers the entire enemy action phase as a
# single block. EnemyHandler internally iterates enemies, applies SOT
# statuses, runs the declare/await-block/do-action loop, applies EOT
# statuses, and finally emits Events.enemy_phase_ended.
#
# We just wait for that one signal and transition to ENEMY_EOT.
#
# Replaces the connect at battle.gd:19 pre-refactor:
#   Events.enemy_phase_ended.connect(_on_enemy_phase_ended)
#
# Pass 2 will split this state per-enemy and own the
#   declare → await(player_blocks_declared) → do_action
# loop directly, which is the place the current code can deadlock if
# blocks are never declared.
class_name EnemyActingState
extends TurnState


func enter() -> void:
	Events.enemy_phase_ended.connect(_on_enemy_phase_ended)


func exit() -> void:
	if Events.enemy_phase_ended.is_connected(_on_enemy_phase_ended):
		Events.enemy_phase_ended.disconnect(_on_enemy_phase_ended)


func _on_enemy_phase_ended() -> void:
	_request(State.ENEMY_EOT)
