## Animates an enemy's multi-card block sequence: pluck card from hand, travel
## to BlockDisplay, pop "+X" badge, hold, fade to discard. Extracted from
## enemy.gd so the timing-sensitive tween chain has a single owner.
##
## Public surface:
##   defend_against_attack(attack, go_again, on_hits)
##
## Block stats are applied synchronously inside defend_against_attack so that
## AttackDamageEffect.execute_single_target sees the updated stats.block when
## it calls take_damage immediately after this returns. The animation runs as
## a fire-and-forget coroutine.
class_name EnemyDefenseSequencer
extends Node

const BLOCK_BADGE_SCENE := preload("res://scenes/enemy/block_badge.tscn")

## Block-card visualization tunables.
const CARD_PIVOT_OFFSET := Vector2(100, 140)  # Matches CardUI scene pivot.
const BLOCK_DISPLAY_SCALE := 0.55
const BLOCK_TRAVEL_DURATION := 0.3
const BLOCK_HOLD_DURATION := 0.5
const BLOCK_BADGE_LOCAL_OFFSET := Vector2(0, -110)  # Above the displayed card.
const BLOCK_BADGE_SIZE := Vector2(80, 40)           # Must match block_badge.tscn.
const BLOCK_BADGE_Z_INDEX := 20                     # Above card_ui.z_index (10).

var _enemy: Enemy
var _hand_manager: EnemyHandManager
var _enemy_hand: EnemyHand
var _block_display: Node2D


func setup(enemy: Enemy, hand_manager: EnemyHandManager,
		enemy_hand: EnemyHand, block_display: Node2D) -> void:
	_enemy = enemy
	_hand_manager = hand_manager
	_enemy_hand = enemy_hand
	_block_display = block_display


func defend_against_attack(attack: int, go_again: bool, incoming_on_hits: Array[OnHit]) -> void:
	_log("defending attack=%d  go_again=%s  hand=%d  ai_hand=%d" % [
		attack, go_again, _hand_manager.hand.size(), _enemy.enemy_ai.hand.size()])
	var defense_array := _enemy.enemy_ai.defend(attack, go_again, incoming_on_hits)

	# Apply block synchronously so AttackDamageEffect.execute_single_target sees
	# the updated stats.block when it calls take_damage right after this returns.
	var anim_queue: Array = []
	for def_card: Card in defense_array:
		var amount: int = _enemy.modifier_handler.get_modified_value(
			def_card.defense, Modifier.Type.BLOCK_GAINED)
		_enemy.stats.block += amount
		anim_queue.append({"card": def_card, "amount": amount})

	_log("after defend  hand=%d  ai_hand=%d  ui_map=%d" % [
		_hand_manager.hand.size(), _enemy.enemy_ai.hand.size(),
		_hand_manager.card_ui_map.size()])

	# Animation runs as a fire-and-forget coroutine so defend stays sync.
	_play_block_sequence(anim_queue)


## Run the per-card block animation sequentially. Hand removal is deferred into
## each card's animation so cards stay in EnemyHand until their own turn comes —
## otherwise multi-card blocks would all hover above the hand at once.
func _play_block_sequence(queue: Array) -> void:
	for entry in queue:
		await _animate_block_card(entry.card, entry.amount)


func _animate_block_card(card: Card, amount: int) -> void:
	var card_ui: EnemyCardUI = _hand_manager.get_or_create_card_ui(card)
	if not is_instance_valid(card_ui):
		return

	# Pluck from hand: erase data, reparent to BlockDisplay (preserves global pos
	# so the card visibly travels from where it was — no shrink animation).
	# We don't call _hand_manager.remove_card() here because that would also
	# call EnemyHand.remove_card (a tween-out animation we don't want — the
	# card visibly travels to BlockDisplay instead).
	_hand_manager.hand.erase(card)
	_hand_manager.untrack_card_ui(card)
	if card_ui.get_parent() != _block_display:
		card_ui.reparent(_block_display)
	_enemy_hand._arrange_cards()
	_enemy.update_intent()
	_enemy.enemy_resource_ui.update_display(_enemy.enemy_ai)
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_ui.z_index = 10
	card_ui.z_as_relative = true

	# 1 + 2. Travel to BlockDisplay's centered position while flipping face-up.
	# flip_reveal targets card_render.scale:x (an inner Control), so it doesn't
	# fight the outer scale tween from animate_to_local_*.
	card_ui.animate_to_local_position_and_rotation_and_scale(
		-CARD_PIVOT_OFFSET, 0.0, BLOCK_DISPLAY_SCALE, BLOCK_TRAVEL_DURATION
	)
	card_ui.flip_reveal()
	await _enemy.get_tree().create_timer(BLOCK_TRAVEL_DURATION).timeout
	if not is_instance_valid(card_ui):
		return

	# 3. Pop the +X badge above the card; play sound at the moment of feedback.
	var badge: BlockBadge = BLOCK_BADGE_SCENE.instantiate()
	_enemy.add_child(badge)
	# Center the badge on (block_display.position + BLOCK_BADGE_LOCAL_OFFSET)
	# by offsetting its top-left back by half its known size.
	badge.position = _block_display.position + BLOCK_BADGE_LOCAL_OFFSET - BLOCK_BADGE_SIZE * 0.5
	badge.z_index = BLOCK_BADGE_Z_INDEX
	badge.pop(amount)
	SFXPlayer.play(card.block_sound)

	await _enemy.get_tree().create_timer(BLOCK_HOLD_DURATION).timeout
	if not is_instance_valid(card_ui):
		return

	# 4. Send to discard: data-side add + visual fadeout.
	_enemy.stats.discard.add_card(card)
	var t := card_ui.create_tween()
	t.tween_property(card_ui, "scale", Vector2.ZERO, Constants.TWEEN_FADE)
	t.parallel().tween_property(card_ui, "modulate:a", 0.0, Constants.TWEEN_FADE)
	await t.finished
	if is_instance_valid(card_ui):
		card_ui.queue_free()


func _log(msg: String) -> void:
	print("[EnemyDefense:%s] %s" % [_enemy.stats.character_name if _enemy and _enemy.stats else "?", msg])
