## Animates an enemy's defense reaction (blocks + defensive pitches) per
## DamagePacket. EnemyAI.defend_packet does the data-side work (chooses the
## allocation, mutates stats.block / stats.mana, and removes cards from
## hand); this sequencer turns the result into the per-card travel +
## badge-pop animation. Extracted from enemy.gd so the timing-sensitive
## tween chain has a single owner.
##
## Public surface:
##   animate_defense(result)
##   where `result` is the Dictionary returned by EnemyAI.defend_packet:
##     {"blocked": Array[Card], "pitched": Array[Card], "prevention": int}
##
## Block stats (stats.block) and pitched mana (stats.mana) are already in
## place by the time this is called — defend_packet committed them up
## front so AttackDamageEffect / ZapEffect see the right values when they
## run immediately after. Pile disposition (exhaust for blocks, discard for
## pitches) also already happened via the card lifecycle signals emitted by
## defend_packet (EnemyHandManager handlers route to the right pile). The
## animation is a fire-and-forget coroutine.
class_name EnemyDefenseSequencer
extends Node

const BLOCK_BADGE_SCENE := preload("res://scenes/enemy/block_badge.tscn")
const MANA_ICON := preload("res://art/gold.png")

## Defense-card visualization tunables.
const CARD_PIVOT_OFFSET := Vector2(100, 140)  # Matches CardUI scene pivot.
const DEFENSE_DISPLAY_SCALE := 0.55
const DEFENSE_TRAVEL_DURATION := 0.3
const DEFENSE_HOLD_DURATION := 0.5
const DEFENSE_BADGE_LOCAL_OFFSET := Vector2(0, -110)  # Above the displayed card.
const DEFENSE_BADGE_SIZE := Vector2(80, 40)           # Must match block_badge.tscn.
const DEFENSE_BADGE_Z_INDEX := 20                     # Above card_ui.z_index (10).

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


func animate_defense(result: Dictionary) -> void:
	var blocked: Array = result.get("blocked", [])
	var pitched: Array = result.get("pitched", [])
	if blocked.is_empty() and pitched.is_empty():
		return
	_log("animating defense  blocked=%d  pitched=%d" % [blocked.size(), pitched.size()])

	var anim_queue: Array = []
	for card: Card in blocked:
		# Block amount with BLOCK_GAINED applied; mirrors what defend_packet
		# committed to stats.block, so the badge label matches reality.
		var amount: int = _enemy.modifier_handler.get_modified_value(
			card.defense, Modifier.Type.BLOCK_GAINED)
		anim_queue.append({"card": card, "amount": amount, "kind": "block"})
	for card: Card in pitched:
		anim_queue.append({"card": card, "amount": card.pitch, "kind": "pitch"})

	# Coroutine — this returns immediately so DamagePacket can land damage
	# without waiting for the visual sequence.
	_play_defense_sequence(anim_queue)


## Run each defensive card animation sequentially.
func _play_defense_sequence(queue: Array) -> void:
	for entry in queue:
		await _animate_defense_card(entry.card, entry.amount, entry.kind)


func _animate_defense_card(card: Card, amount: int, kind: String) -> void:
	var card_ui: EnemyCardUI = _hand_manager.get_or_create_card_ui(card)
	if not is_instance_valid(card_ui):
		return

	# Reparent the card_ui to the defense display. We don't go through
	# _hand_manager.remove_card here because the card has already been
	# removed from the data hand by defend_packet; this is purely visual.
	_hand_manager.untrack_card_ui(card)
	if card_ui.get_parent() != _block_display:
		card_ui.reparent(_block_display)
	_enemy_hand._arrange_cards()
	_enemy.update_intent()
	_enemy.enemy_resource_ui.update_display(_enemy.enemy_ai)
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_ui.z_index = 10
	card_ui.z_as_relative = true

	# Travel to defense display while flipping face-up. flip_reveal targets
	# card_render.scale:x (an inner Control), so it doesn't fight the outer
	# scale tween from animate_to_local_*.
	card_ui.animate_to_local_position_and_rotation_and_scale(
		-CARD_PIVOT_OFFSET, 0.0, DEFENSE_DISPLAY_SCALE, DEFENSE_TRAVEL_DURATION
	)
	card_ui.flip_reveal()
	await _enemy.get_tree().create_timer(DEFENSE_TRAVEL_DURATION).timeout
	if not is_instance_valid(card_ui):
		return

	# Pop the badge above the card; play sound at the moment of feedback.
	var badge: BlockBadge = BLOCK_BADGE_SCENE.instantiate()
	_enemy.add_child(badge)
	badge.position = _block_display.position + DEFENSE_BADGE_LOCAL_OFFSET - DEFENSE_BADGE_SIZE * 0.5
	badge.z_index = DEFENSE_BADGE_Z_INDEX
	if kind == "pitch":
		badge.set_icon(MANA_ICON)
	badge.pop(amount)
	SFXPlayer.play(card.block_sound)

	await _enemy.get_tree().create_timer(DEFENSE_HOLD_DURATION).timeout
	if not is_instance_valid(card_ui):
		return

	# Pile disposition is signal-driven now: defend_packet emits `blocked` /
	# calls pitch_card before this animation runs, and EnemyHandManager's
	# handlers route to exhaust / discard respectively. Nothing to do here.
	var t := card_ui.create_tween()
	t.tween_property(card_ui, "scale", Vector2.ZERO, Constants.TWEEN_FADE)
	t.parallel().tween_property(card_ui, "modulate:a", 0.0, Constants.TWEEN_FADE)
	await t.finished
	if is_instance_valid(card_ui):
		card_ui.queue_free()


func _log(msg: String) -> void:
	print("[EnemyDefense:%s] %s" % [_enemy.stats.character_name if _enemy and _enemy.stats else "?", msg])
