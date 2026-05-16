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

## Either a Card (from hand) or a Weapon (from stats.hand_left). Branches in
## declare / pre_block_reveal / do_action check the concrete type.
var current_action: Object

var _enemy: Enemy
var _hand_manager: EnemyHandManager
var _staged_display: EnemyStagedDisplay
var _enemy_resource_ui: EnemyResourceUI
var _staged_card_ui: EnemyCardUI = null


func setup(enemy: Enemy, hand_manager: EnemyHandManager,
		staged_display: EnemyStagedDisplay,
		enemy_resource_ui: EnemyResourceUI) -> void:
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
	# Weapons aren't in the hand, so they skip this pre-capture entirely.
	var pending_card_ui: EnemyCardUI = null
	if enemy_ai.turn_plan and enemy_ai.turn_plan.actions.size() > 0:
		var pending = enemy_ai.turn_plan.actions[0]
		if pending is Card:
			_hand_manager.set_pending_stage(pending)
			pending_card_ui = _hand_manager.get_card_ui(pending)

	current_action = await enemy_ai.play_next_action()
	_hand_manager.clear_pending_stage()
	_enemy.update_intent()
	_enemy_resource_ui.update_display(enemy_ai)

	# When current_action is null the enemy's plan is exhausted; EnemyActingState
	# observes that directly and exits its loop. Otherwise stage the action —
	# enemy_attack_declared is emitted in run_pre_block_reveal AFTER the reveal
	# so the BLOCK button can't be armed mid-reveal (which would lose the
	# player_blocks_declared signal and soft-lock the turn).
	if current_action != null:
		if current_action is Card:
			var staged_card: Card = current_action as Card
			_log("declaring %s: %s" % [Card.Type.keys()[staged_card.type], staged_card.id])
			_stage_attack_card_ui(staged_card, pending_card_ui)
		elif current_action is Weapon:
			_log("declaring weapon: %s" % (current_action as Weapon).id)
			await _stage_weapon_badge()


## Run any pre-block reveal effects on the staged card (e.g. ravenous_rabble
## flipping the top card of the deck), then refresh the intent so the displayed
## damage reflects the reveal. Awaited by EnemyActingState before player blocks.
##
## enemy_attack_declared is emitted here (post-reveal) rather than in
## declare_next_attack so the BLOCK button only arms after the reveal animation
## finishes. Otherwise a click during the reveal would emit
## player_blocks_declared while the state is still awaiting the reveal — the
## signal would be lost and the turn would soft-lock at the next await.
## NAAs deal no player damage and auto-resolve after a brief hold, so they
## skip the emit.
func run_pre_block_reveal() -> void:
	if not current_action:
		return
	if current_action is Card:
		await (current_action as Card).pre_block_reveal(_enemy)
	_enemy.update_intent()
	var is_attack: bool = (current_action is Weapon) \
		or (current_action is Card and (current_action as Card).type == Card.Type.ATTACK)
	if is_attack:
		Events.enemy_attack_declared.emit()


# ── Play ──────────────────────────────────────────────────────────────────────

func do_action() -> void:
	if not current_action:
		return

	var played_attack: bool = (current_action is Weapon) \
		or (current_action is Card and (current_action as Card).type == Card.Type.ATTACK)
	if current_action is Weapon:
		await _do_weapon_action()
	elif played_attack:
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


## Attack path: detach the staged card, then split on `card.exhausts`:
##   • Exhausting cards hand off directly to the enemy's ExhaustPile via
##     accept_incoming_visual. The card_ui slides into the pile and stays there
##     persistently — same handoff pattern the player uses for non-exhausting
##     cards going to the discard pile.
##   • Non-exhausting cards run the play-overlay emphasis + effects pipeline,
##     then slide to the EnemyResourceUI discard count label and fade.
## Disposition (which pile the card data lands in) is driven by
## card.card_play_finished → EnemyHandManager._on_card_play_finished.
func _do_attack_action() -> void:
	var card_ui: EnemyCardUI
	if is_instance_valid(_staged_card_ui):
		# clear_staged() detaches without reparenting (release() would send the
		# card back to the hand first, only for _reparent_to_play_overlay to
		# move it again).
		card_ui = _staged_display.clear_staged()
		_staged_card_ui = null
	else:
		card_ui = _hand_manager.get_or_create_card_ui(current_action as Card)
		_hand_manager.remove_card(current_action as Card)

	if not is_instance_valid(card_ui):
		return

	card_ui.targets = [_enemy.enemy_ai.target]
	var played_card: Card = current_action as Card

	if played_card.exhausts and _enemy.exhaust_pile:
		# Handoff BEFORE card.play() so the size_changed handler triggered by
		# _on_card_play_finished → exhaust.add_card sees visual count already
		# matching the resource and skips its own auto-spawn.
		# accept_pitched_visual (vs accept_incoming_visual) tweens the card on a
		# smooth diagonal from its current global transform directly to the
		# south slot — no horizontal snap, no first-appears-at-north artifact.
		_enemy.exhaust_pile.accept_pitched_visual(card_ui)
		await played_card.play(card_ui, card_ui.targets, _enemy.stats, _enemy.modifier_handler)
	else:
		# Non-exhausting attack: emphasize + effects at the play overlay, then
		# slide to the EnemyResourceUI discard count label and fade.
		card_ui._reparent_to_play_overlay()
		await card_ui._play_emphasis()
		await played_card.play(card_ui, card_ui.targets, _enemy.stats, _enemy.modifier_handler)
		if is_instance_valid(card_ui):
			await _enemy.animate_card_to_discard_label(card_ui)


## NAA path: detach without reparenting back to the hand, then split on
## card.exhausts identically to the attack path.
func _do_naa_action() -> void:
	var card_ui: EnemyCardUI
	if is_instance_valid(_staged_card_ui):
		card_ui = _staged_display.clear_staged()
		_staged_card_ui = null
	else:
		card_ui = _hand_manager.get_or_create_card_ui(current_action as Card)
		_hand_manager.remove_card(current_action as Card)

	if not is_instance_valid(card_ui):
		return

	card_ui.targets = [_enemy.enemy_ai.target]
	var played_card: Card = current_action as Card

	if played_card.exhausts and _enemy.exhaust_pile:
		# accept_pitched_visual (vs accept_incoming_visual) tweens the card on a
		# smooth diagonal from its current global transform directly to the
		# south slot — no horizontal snap, no first-appears-at-north artifact.
		_enemy.exhaust_pile.accept_pitched_visual(card_ui)
		await played_card.play(card_ui, card_ui.targets, _enemy.stats, _enemy.modifier_handler)
	else:
		# Effects resolve at the staged position; no reparent so the card stays
		# centered. Most NAAs target SELF and apply a status.
		await card_ui._play_emphasis()
		await played_card.play(card_ui, card_ui.targets, _enemy.stats, _enemy.modifier_handler)
		if is_instance_valid(card_ui):
			await _enemy.animate_card_to_discard_label(card_ui)


## Weapon path: apply damage via the same DamagePacket pipeline as a card
## swing, then animate the badge back to its home position. We inline the
## relevant pieces of Weapon.activate_weapon (instead of calling it directly)
## because activate_weapon emits Events.player_attack_declared, which
## increments Player.stats.attacks_this_turn — wrong for enemy-wielded weapons.
## Mana / AP / attacks_this_turn / weapon_used_up are handled here to mirror
## the player path's accounting.
func _do_weapon_action() -> void:
	var weapon: Weapon = current_action as Weapon
	var target: Node = _enemy.enemy_ai.target
	if not is_instance_valid(weapon) or not is_instance_valid(target):
		return

	var badge: WeaponHandler = _enemy.weapon_badge
	if is_instance_valid(badge):
		badge.flash()
	if weapon.sound:
		SFXPlayer.play(weapon.sound)

	# Mirror Card.play's order: pay mana, decrement AP (with go_again),
	# apply damage, then zero the target's leftover block.
	_enemy.stats.mana -= weapon.cost
	_enemy.stats.action_points -= 1
	if weapon.go_again:
		_enemy.stats.action_points += 1

	var packet := weapon.build_attack_packet(_enemy.modifier_handler)
	packet.execute([target])

	if is_instance_valid(target):
		target.stats.block = 0

	weapon.attacks_this_turn += 1
	if weapon.attacks_this_turn >= weapon.attacks_per_turn:
		weapon.weapon_used_up.emit()

	await _return_weapon_badge_home()


## Tween the weapon badge from its home offset to the StagedDisplay's local
## position. Both badge and StagedDisplay are children of Enemy in the same
## local coord space, so a direct position tween works without reparenting.
## The badge is a 64×64 Control whose position is its top-left, so we offset
## by half the size to center it on the staged anchor (otherwise it slides
## down-and-right and overlaps the sprite).
func _stage_weapon_badge() -> void:
	var badge: WeaponHandler = _enemy.weapon_badge
	if not is_instance_valid(badge):
		return
	badge.z_index = 1
	var target: Vector2 = _staged_display.position - Vector2(32, 32)
	var tween := badge.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "position", target, Constants.TWEEN_CARD_STAGE)
	await tween.finished


func _return_weapon_badge_home() -> void:
	var badge: WeaponHandler = _enemy.weapon_badge
	if not is_instance_valid(badge):
		return
	var tween := badge.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "position", Enemy.WEAPON_BADGE_OFFSET, Constants.TWEEN_CARD_STAGE)
	await tween.finished
	badge.z_index = 0


# ── Staging ───────────────────────────────────────────────────────────────────

## Move the attack card to this enemy's StagedDisplay (above its sprite),
## face-up. Optionally accepts a pre-captured card_ui to handle the case where
## card_ui_map has already been cleared by the card_removed_from_hand signal.
func _stage_attack_card_ui(card: Card, card_ui: EnemyCardUI) -> void:
	# Fall back to map lookup if no pre-captured ui was provided.
	if not is_instance_valid(card_ui):
		card_ui = _hand_manager.get_card_ui(card)
	if not is_instance_valid(card_ui):
		# Card isn't in the hand display — create a transient ui.
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
