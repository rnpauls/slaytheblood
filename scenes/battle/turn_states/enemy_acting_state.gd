# Per-enemy action loop with explicit cancellation.
#
# Why a state owns this loop:
#   The await Events.player_blocks_declared used to live inside
#   Enemy.declare_next_attack, which made it impossible to cancel from
#   outside. If the enemy died mid-block, the coroutine on the freed
#   enemy was orphaned and the turn would deadlock. Pulling the await
#   into a state means exit() can flip a cancellation flag that the
#   loop checks after every await — single, deterministic interrupt.
#
# Cancellation cases handled:
#   - Current enemy dies (DOT, retaliation, AOE): _on_enemy_died flips
#     _current_enemy_died, loop exits, transitions to ENEMY_SOT to pick
#     the next enemy (skipping EOT statuses on the corpse).
#   - Player dies during do_action: Battle._on_player_died forces
#     DEFEAT, our exit() flips _cancelled, loop returns silently.
#   - Last enemy dies: Battle._on_enemies_child_order_changed forces
#     VICTORY, our exit() flips _cancelled, loop returns silently.
class_name EnemyActingState
extends TurnState

## Time the staged NAA card holds at center before auto-resolving. Long enough
## for the player to read the card; short enough that NAA-heavy turns don't drag.
const NAA_HOLD_DURATION := 0.6

var _current_enemy: Enemy
var _cancelled := false  # exit() called externally — bail without requesting
var _current_enemy_died := false  # current enemy died mid-loop — go to next ENEMY_SOT


func enter() -> void:
	_cancelled = false
	_current_enemy_died = false

	if enemy_handler.acting_enemies.is_empty():
		# Shouldn't normally happen — ENEMY_SOT would have routed elsewhere.
		_request.call_deferred(State.PLAYER_SOT)
		return

	_current_enemy = enemy_handler.acting_enemies[0]
	if not is_instance_valid(_current_enemy):
		_request.call_deferred(State.ENEMY_SOT)
		return

	Events.enemy_died.connect(_on_enemy_died)
	_run_action_loop()


func exit() -> void:
	_cancelled = true
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)


func _on_enemy_died(enemy: Enemy) -> void:
	if enemy == _current_enemy:
		_current_enemy_died = true


func _run_action_loop() -> void:
	while true:
		# declare_next_attack is now synchronous: it sets current_action,
		# stages the card UI, and emits enemy_attack_declared (which flips
		# the END button to BLOCK in BattleUI). It no longer awaits.
		_current_enemy.declare_next_attack()
		if _cancelled:
			return
		if _current_enemy_died:
			break
		if _current_enemy.current_action == null:
			# Plan exhausted — normal end of this enemy's actions.
			break

		# Run any pre-block reveal on the staged card (e.g. ravenous_rabble flips
		# the top of the deck) so the player sees the actual damage and reveal
		# before deciding how to block.
		await _current_enemy.run_pre_block_reveal()
		if _cancelled:
			return
		if _current_enemy_died:
			break

		# Attacks: wait for the player to declare blocks (END button in BLOCK mode).
		# NAAs: deal no player damage, so we hold briefly at the staged position
		# instead of prompting — Enemy.declare_next_attack skips the
		# enemy_attack_declared emit for NAAs so the END button never flips.
		if _current_enemy.current_action.type == Card.Type.ATTACK:
			await Events.player_blocks_declared
		else:
			await get_tree().create_timer(NAA_HOLD_DURATION).timeout
		if _cancelled:
			return
		if _current_enemy_died:
			break

		# do_action awaits card_ui.play() internally (animation), then
		# emits enemy_action_completed + attack_completed.
		await _current_enemy.do_action()
		if _cancelled:
			return
		if _current_enemy_died:
			break

	if _cancelled:
		return
	if _current_enemy_died:
		# Skip EOT statuses (no live owner to apply them to) and pick
		# the next enemy.
		_request(State.ENEMY_SOT)
	else:
		_request(State.ENEMY_EOT)
