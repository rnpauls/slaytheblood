## Splitter: passive on a slime-style enemy. The first time the bearer takes
## damage that drops them to or below half HP (without killing them), the
## bearer is consumed and TWO Mini-Slimes spawn in their place — inheriting
## the parent's remaining cards split alternately between them. One-shot per
## battle.
##
## Implementation notes:
##   - Parent cards are gathered from draw_pile + discard + hand (exhaust
##     pile is intentionally excluded; those cards are gone for the fight).
##   - Each mini's auto-drawn starting hand is cleared first so we don't
##     mix in cards from the mini's own starting_deck — only parent cards
##     end up in mini hands.
##   - Parent is freed via _on_death (NOT queue_free directly) so the
##     enemy_died signal fires and EnemyHandler.acting_enemies stays clean.
##     stats.health is forced to 0 first so any listener checking the
##     bearer's HP sees a consistent "dead" state.
##   - Killing blow (parent goes to 0 HP directly) is intentionally NOT a
##     split: spawning replacements from a corpse is a confusing moment.
class_name SplitterStatus
extends Status

const MINI_SLIME_STATS := preload("res://enemies/slime/mini_slime_enemy.tres")
const STUNNED_STATUS := preload("res://statuses/stunned.tres")
const SPAWN_OFFSETS: Array[Vector2] = [Vector2(-110, -20), Vector2(110, -20)]

var _has_split: bool = false
var _bearer: Enemy = null
var _bound_check: Callable


func get_tooltip() -> String:
	if _has_split:
		return tooltip + " (already split)"
	return tooltip


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	_bound_check = _on_combatant_damaged
	Events.combatant_damaged.connect(_bound_check)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_combatant_damaged(victim: Node, _attacker: Node, _damage: int) -> void:
	if _has_split:
		return
	if victim != _bearer:
		return
	if not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	if _bearer.stats.health <= 0:
		# Killed by this hit — no minis appear from a corpse.
		return
	var half_hp := float(_bearer.stats.max_health) / 2.0
	if float(_bearer.stats.health) > half_hp:
		return
	_has_split = true
	# Defer one frame so the damage flash / take_damage tween completes before
	# we tear the bearer out from under it.
	call_deferred("_perform_split")


func _perform_split() -> void:
	if not is_instance_valid(_bearer):
		return
	var handler := _bearer.get_parent()
	if handler == null or not handler.has_method("spawn_enemy"):
		return

	# Gather everything the bearer still has access to. Exhaust pile is
	# intentionally left behind — those cards are out of the battle.
	var inherited: Array[Card] = []
	if _bearer.stats.draw_pile:
		inherited.append_array(_bearer.stats.draw_pile.cards)
	if _bearer.stats.discard:
		inherited.append_array(_bearer.stats.discard.cards)
	if _bearer.hand:
		inherited.append_array(_bearer.hand)

	# Spawn the minis at the bearer's position before tearing the bearer down
	# so the visual handoff reads as "slime splits in place".
	var base_pos := _bearer.position
	var minis: Array = []
	for off in SPAWN_OFFSETS:
		var m = handler.spawn_enemy(MINI_SLIME_STATS, base_pos + off)
		if m != null:
			minis.append(m)

	for m in minis:
		if is_instance_valid(m) and m.status_handler:
			m.status_handler.add_status(STUNNED_STATUS.duplicate())

	if not minis.is_empty():
		_replace_decks_with_parent_cards(minis, inherited)

	# Tear down the parent. health = 0 ensures any listener inspecting the
	# bearer's stats during the death tween sees a consistent "dead" reading.
	_bearer.stats.health = 0
	# Fire-and-forget: enemy_died emits synchronously inside _on_death so the
	# EnemyHandler bookkeeping (acting_enemies erase) happens immediately.
	_bearer._on_death()


func _replace_decks_with_parent_cards(minis: Array, parent_cards: Array) -> void:
	# spawn_enemy already auto-drew cards_per_turn from each mini's starting
	# deck. Wipe those (we want only parent cards in mini hands) and fill the
	# draw piles with the inherited cards split alternately. Then each mini
	# draws its real starting hand from the inherited pool.
	for m in minis:
		if not is_instance_valid(m):
			continue
		var initial_hand: Array = m.hand.duplicate()
		for c in initial_hand:
			if m.hand_manager:
				m.hand_manager.remove_card(c)
		if m.stats.draw_pile:
			m.stats.draw_pile.cards.clear()
			m.stats.draw_pile.card_pile_size_changed.emit(0)
		if m.stats.discard:
			m.stats.discard.cards.clear()
			m.stats.discard.card_pile_size_changed.emit(0)

	for i in parent_cards.size():
		var card: Card = parent_cards[i]
		if card == null:
			continue
		# Detach from parent; mini.draw_card re-owns it.
		card.owner = null
		var target_mini = minis[i % minis.size()]
		if is_instance_valid(target_mini) and target_mini.stats.draw_pile:
			target_mini.stats.draw_pile.add_card(card)

	for m in minis:
		if not is_instance_valid(m) or m.stats.draw_pile == null:
			continue
		m.stats.draw_pile.shuffle()
		m.draw_cards(m.stats.cards_per_turn)


func _exit_tree() -> void:
	if _bound_check and Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.disconnect(_bound_check)
