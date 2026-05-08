## Coordinates the per-action play loop for an Enemy: declare → optional
## pre-block reveal → play. Also owns the "currently staged card" tracking.
## Extracted from enemy.gd as a RefCounted helper (no scene-tree presence,
## no tweens of its own — delegates to card_ui / enemy for animation work).
##
## Public surface (called by Enemy facade and TurnState states via Enemy):
##   declare_next_attack()
##   run_pre_block_reveal()
##   do_action()
##   current_action: Card (getter / setter)
##   stage_card(card)        — internal staging, exposed for completeness
##   unstage_card()
class_name EnemyActionSequencer
extends RefCounted

var current_action: Card

var _enemy: Enemy
var _hand_manager: EnemyHandManager
var _staged_display: EnemyStagedDisplay
var _enemy_resource_ui: EnemyResourceUI
var _staged_card_ui: EnemyCardUI = null


func setup(enemy: Enemy, hand_manager: EnemyHandManager,
		staged_display: EnemyStagedDisplay, enemy_resource_ui: EnemyResourceUI) -> void:
	_enemy = enemy
	_hand_manager = hand_manager
	_staged_display = staged_display
	_enemy_resource_ui = enemy_resource_ui


# ── Declare ───────────────────────────────────────────────────────────────────

func declare_next_attack() -> void:
	var enemy_ai := _enemy.enemy_ai
	if not enemy_ai:
		return

	# Flag the upcoming action card so HandManager's AI signal handler skips
	# its visual removal — staged_display.stage() will reparent the same card_ui.
	var pending_card_ui: EnemyCardUI = null
	if enemy_ai.turn_plan and enemy_ai.turn_plan.actions.size() > 0:
		var pending_card: Card = enemy_ai.turn_plan.actions[0]
		_hand_manager.set_pending_stage(pending_card)
		pending_card_ui = _hand_manager.get_card_ui(pending_card)

	current_action = enemy_ai.play_next_action()
	_hand_manager.clear_pending_stage()
	_enemy.update_intent()
	_enemy_resource_ui.update_display(enemy_ai)

	# When current_action is null the enemy's plan is exhausted; EnemyActingState
	# observes that directly and exits its loop. Otherwise stage the card and
	# announce the attack — the state owns the await player_blocks_declared
	# and the do_action call so cancellation on death is deterministic.
	#
	# enemy_attack_declared flips the END button to BLOCK in BattleUI, so we
	# only emit it for actual attacks. NAAs deal no damage to the player, so
	# they auto-resolve after a brief hold (handled in EnemyActingState).
	if current_action != null:
		_log("declaring %s: %s" % [Card.Type.keys()[current_action.type], current_action.id])
		_stage_attack_card_ui(current_action, pending_card_ui)
		if current_action.type == Card.Type.ATTACK:
			Events.enemy_attack_declared.emit()


## Run any pre-block reveal effects on the staged card (e.g. ravenous_rabble
## flipping the top card of the deck), then refresh the intent so the displayed
## damage reflects the reveal. Awaited by EnemyActingState before player blocks.
func run_pre_block_reveal() -> void:
	if not current_action:
		return
	await current_action.pre_block_reveal(_enemy)
	_enemy.update_intent()


# ── Play ──────────────────────────────────────────────────────────────────────

func do_action() -> void:
	if not current_action:
		return

	var played_attack: bool = current_action.type == Card.Type.ATTACK
	if played_attack:
		await _do_attack_action()
	else:
		await _do_naa_action()

	_enemy.enemy_action_completed.emit(_enemy)
	# Only attacks should fire attack_completed — otherwise statuses that
	# decrement on it (poison_tip, empowered) get burned by NAAs like
	# poison_the_blade played beforehand.
	if played_attack:
		_enemy.attack_completed.emit()
	_enemy_resource_ui.update_display(_enemy.enemy_ai)


## Attack path: release the staged card and let card_ui.play() run its full
## attack/hit animation pipeline. card_ui detaches itself and queue_frees.
## After play resolves, the card resource is routed to exhaust or discard so
## AI replanning + reshuffle_discard see a correct mirror of the deck cycle.
func _do_attack_action() -> void:
	var card_ui: EnemyCardUI
	if is_instance_valid(_staged_card_ui):
		card_ui = _staged_display.release()
		_staged_card_ui = null
	else:
		card_ui = _hand_manager.get_or_create_card_ui(current_action)
		_hand_manager.remove_card(current_action)

	var played_card := current_action
	card_ui.targets = [_enemy.enemy_ai.target]
	await card_ui.play()

	if played_card.exhausts:
		_enemy.stats.exhaust.add_card(played_card)
	else:
		_enemy.stats.discard.add_card(played_card)


## NAA path: apply effects in-place at the staged position, then burn the card
## up before dropping the Card resource into stats.discard. We bypass
## card_ui.play() so the visual stays at center during effects (no flash back
## to hand).
func _do_naa_action() -> void:
	var card_ui: EnemyCardUI
	if is_instance_valid(_staged_card_ui):
		card_ui = _staged_display.clear_staged()
		_staged_card_ui = null
	else:
		card_ui = _hand_manager.get_or_create_card_ui(current_action)
		_hand_manager.remove_card(current_action)

	if not is_instance_valid(card_ui):
		return

	card_ui.targets = [_enemy.enemy_ai.target]
	var played_card := current_action

	# Effects resolve while the card is still visible at the staged position.
	# Most NAAs target SELF and apply a status; card.play handles target lookup.
	await card_ui._play_emphasis()
	await played_card.play(card_ui, card_ui.targets, _enemy.stats, _enemy.modifier_handler)
	if not is_instance_valid(card_ui):
		return

	await card_ui._burn_up()

	if played_card.exhausts:
		_enemy.stats.exhaust.add_card(played_card)
	else:
		_enemy.stats.discard.add_card(played_card)

	if is_instance_valid(card_ui):
		card_ui.queue_free()


# ── Staging ───────────────────────────────────────────────────────────────────

## Move the attack card to this enemy's StagedDisplay (above its sprite),
## face-up. Optionally accepts a pre-captured card_ui to handle the case where
## card_ui_map has already been cleared by the card_removed_from_hand signal.
func _stage_attack_card_ui(card: Card, card_ui: EnemyCardUI) -> void:
	# Fall back to map lookup if no pre-captured ui was provided.
	if not is_instance_valid(card_ui):
		card_ui = _hand_manager.get_card_ui(card)
	if not is_instance_valid(card_ui):
		# Card isn't in the hand display (e.g. arsenal) — create a transient ui.
		card_ui = _hand_manager.get_or_create_card_ui(card)

	_staged_card_ui = card_ui

	# Reveal the card face before staging.
	if card_ui.show_back:
		card_ui.show_back = false

	_staged_display.stage(card_ui)


func unstage_card() -> void:
	if is_instance_valid(_staged_card_ui):
		_staged_display.unstage()
	_staged_card_ui = null


func _log(msg: String) -> void:
	print("[EnemyAction:%s] %s" % [_enemy.stats.character_name if _enemy and _enemy.stats else "?", msg])
