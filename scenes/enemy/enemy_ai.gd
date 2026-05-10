class_name EnemyAI
extends Node

var enemy: Enemy # Reference to enemy object (with life, intellect)
#var deck: CardPile # Array of card objects (Card class)
var hand: Array # Current hand
#var life: int
var arsenal: Card = null # Single Card or null
var turn_plan = null # Stores the planned turn {damage, pitched, actions, remaining}
var resources := 0 # Tracks resources available this turn
## Cards that cannot be used to block or pitch this turn due to Intimidate.
## Set by IntimidatedStatus.
var intimidated_cards: Array[Card] = []
var modifier_handler: ModifierHandler

@export var target: Node2D#: set = _set_target

signal plan_created(enemy: Enemy)
## Emitted whenever the AI removes a card from its hand (pitch, play, block, arsenal).
## Enemy.gd connects to this to keep the visual hand in sync.
signal card_removed_from_hand(card: Card)

## Assign the player as target. Caller (Enemy.setup_ai via EnemyHandler)
## passes the player ref so we don't have to look it up by group.
func setup(player_target: Player = null) -> void:
	target = player_target

## Start the AI's turn by planning actions
func start_turn(player_life: int) -> void:
	turn_plan = calculate_max_offense_now(player_life)
	resources = 0
	plan_created.emit(enemy)

## Recalculate turn_plan mid-turn (e.g. after drawing or discarding a card).
## Does NOT reset resources or re-emit plan_created — the turn is already underway.
func recalculate_plan(player_life: int) -> void:
	turn_plan = calculate_max_offense_now(player_life)

## Play the next action in turn_plan, returns card to the enemy node
## Pitches cards as needed
## Arsenals if out of actions
func play_next_action() -> Card:
	if not turn_plan or turn_plan.actions.size() == 0:
		if turn_plan and turn_plan.remaining.size() > 0 and not arsenal:
			# Don't arsenal the lone remaining card if it's costly — arsenal can't
			# be pitched, so it'd be stranded if next turn's draws don't bring
			# enough resources to play it. Keeping it in hand at least preserves
			# its pitch utility.
			var only_costly: bool = turn_plan.remaining.size() == 1 and turn_plan.remaining[0].cost > 0
			if not only_costly:
				arsenal = pick_best_arsenal(turn_plan.remaining)
				hand.erase(arsenal)
				card_removed_from_hand.emit(arsenal)
				print_enemy_ai("arsenaled %s" % arsenal.id)
			else:
				print_enemy_ai("kept %s in hand (lone costly card)" % turn_plan.remaining[0].id)
		turn_plan = null
		return null
	
	var next_action = turn_plan.actions[0]
	
	while resources < next_action.cost and turn_plan.pitched.size() > 0:
		var pitch = turn_plan.pitched[0]
		resources += pitch.pitch
		# pitch_card increments stats.mana AND emits `pitched`, which
		# EnemyHandManager._on_card_pitched routes to the discard pile. The
		# stats.mana mirror keeps the running tally non-negative so subsequent
		# Card.play calls (which decrement stats.mana -= cost) don't corrupt
		# arcane prevention math in defend_packet. cleanup_phase resets
		# stats.mana at end of enemy phase.
		pitch.pitch_card(enemy.stats)
		hand.erase(pitch)
		card_removed_from_hand.emit(pitch)
		turn_plan.pitched.erase(pitch)
		print_enemy_ai("pitched %s for %d" % [pitch.id, pitch.pitch])
	
	if resources < next_action.cost:
		turn_plan.actions.erase(next_action)
		print_enemy_ai("ran out of resources for %s" % next_action.id)
		return null
	
	resources -= next_action.cost
	if next_action == arsenal:
		arsenal = null
		print_enemy_ai("played arsenal %s" % [next_action.id])
	else:
		hand.erase(next_action)
		card_removed_from_hand.emit(next_action)
		print_enemy_ai("played %s" % [next_action.id])
	turn_plan.actions.erase(next_action)
	return next_action

## Defending phase: Player sends a DamagePacket (physical + arcane combined).
## Picks the best allocation of hand cards across {BLOCK, PITCH, KEEP} by
## enumerating all combinations and scoring each. Survival-first: any
## allocation that keeps the enemy alive beats any that doesn't, regardless
## of offense preserved. Side effects: applies block to stats.block, pitch
## values to stats.mana, removes used cards from hand (emits
## card_removed_from_hand so _on_hand_changed re-plans the turn). Returns
## a Dictionary {"blocked": Array[Card], "pitched": Array[Card],
## "prevention": int} for the sequencer to animate.
##
## Replaces the old split decision (defend() for physical,
## decide_arcane_prevention() for arcane) which couldn't see the combined
## damage and let the enemy die to {phys + arc} totals when neither portion
## was lethal alone.
##
## Combinatorics: 3^N over hand-size N. With N <= 6, ~729 options; per
## option, calculate_max_offense is recursively O(2^N). Total work is
## small at typical enemy hand sizes.
##
## Note on DMG_TAKEN: this evaluates against modifier-adjusted physical
## (so block sufficiency is judged correctly). Stats.take_damage applies
## DMG_TAKEN once on its own; both halves see the same modified value so
## block math stays consistent.
##
## BLOCK_GAINED: applied per-card during option scoring AND at commit,
## so the AI never under-counts buffed defense.
func defend_packet(packet: DamagePacket) -> Dictionary:
	var physical_raw: int = packet.physical
	var arcane: int = packet.arcane
	if physical_raw <= 0 and arcane <= 0:
		return {"blocked": [] as Array[Card], "pitched": [] as Array[Card], "prevention": 0}

	var physical: int = 0
	if physical_raw > 0:
		physical = modifier_handler.get_modified_value(physical_raw, Modifier.Type.DMG_TAKEN)

	# Defensive clamp: stats.mana can drift negative if pre-existing accounting
	# bugs leak through (Card.play decrements stats.mana for any player), so we
	# treat negative mana as 0 for scoring purposes — preventing the algorithm
	# from over-pitching to "make up" phantom arcane damage from the
	# `max(0, arcane - negative_prevention)` term.
	var current_mana: int = max(0, enemy.stats.mana)
	var current_hp: int = enemy.stats.health

	# Build candidate list. Hand cards may take any role subject to flags.
	# Arsenal can BLOCK only if it's a Type.BLOCK card (F&B rule); never PITCH.
	var candidates: Array = []
	for c: Card in hand:
		var can_block_c: bool = (not c.disable_defense) and (not (c in intimidated_cards))
		var can_pitch_c: bool = (not c.disable_pitch) and (not (c in intimidated_cards))
		candidates.append({"card": c, "is_arsenal": false, "can_block": can_block_c, "can_pitch": can_pitch_c})
	var arsenal_in_candidates := false
	if arsenal and arsenal.type == Card.Type.BLOCK:
		var can_block_arsenal: bool = (not arsenal.disable_defense) and (not (arsenal in intimidated_cards))
		if can_block_arsenal:
			candidates.append({"card": arsenal, "is_arsenal": true, "can_block": true, "can_pitch": false})
			arsenal_in_candidates = true

	# Baseline offense if we keep everything (no defense). Used for offense_lost.
	var max_offense_baseline: int = calculate_max_offense(
		{"cards": hand.duplicate(), "resources": 0, "arsenal": arsenal}, 1, enemy.stats.health
	)["damage"]

	var n: int = candidates.size()
	var total: int = 1
	for _i in n:
		total *= 3

	var best: Dictionary = {}
	var best_survives: bool = false
	var best_score: float = INF
	var best_offense_after: int = -1
	var best_cards_used: int = 1 << 30  # higher = worse; tiebreaker prefers fewer cards spent

	for mask in total:
		var blocked_cards: Array[Card] = []
		var pitched_cards: Array[Card] = []
		var keep_cards: Array[Card] = []
		var keep_arsenal: Card = arsenal if not arsenal_in_candidates else null
		var valid := true
		var rem := mask
		for i in n:
			var role: int = rem % 3  # 0=KEEP, 1=BLOCK, 2=PITCH
			@warning_ignore("integer_division") rem = rem / 3
			var ent: Dictionary = candidates[i]
			match role:
				0:
					if ent.is_arsenal:
						keep_arsenal = ent.card
					else:
						keep_cards.append(ent.card)
				1:
					if not ent.can_block:
						valid = false
						break
					blocked_cards.append(ent.card)
				2:
					if not ent.can_pitch:
						valid = false
						break
					pitched_cards.append(ent.card)
		if not valid:
			continue

		var block_total := 0
		for c: Card in blocked_cards:
			block_total += modifier_handler.get_modified_value(c.defense, Modifier.Type.BLOCK_GAINED)
		var mana_gained := 0
		for c: Card in pitched_cards:
			mana_gained += c.pitch
		var prevention: int = mini(arcane, current_mana + mana_gained)
		var damage_taken: int = max(0, physical - block_total) + max(0, arcane - prevention)
		var survives: bool = damage_taken < current_hp

		var offense_after: int = calculate_max_offense(
			{"cards": keep_cards, "resources": 0, "arsenal": keep_arsenal}, 1, enemy.stats.health
		)["damage"]
		var offense_lost: int = max_offense_baseline - offense_after
		var score: float = float(damage_taken) + float(offense_lost)

		var cards_used: int = blocked_cards.size() + pitched_cards.size()
		var should_replace := false
		if best.is_empty():
			should_replace = true
		elif survives and not best_survives:
			should_replace = true
		elif survives == best_survives:
			if score < best_score:
				should_replace = true
			elif score == best_score:
				if offense_after > best_offense_after:
					should_replace = true
				elif offense_after == best_offense_after and cards_used < best_cards_used:
					# Final tiebreaker: prefer using fewer cards (preserve hand
					# for future turns). Without this, the enumerator picks the
					# first survival mask found, which can over-spend cards on a
					# zero-marginal-utility allocation (e.g. 1B+2P when 1B+1P+1K
					# already survives).
					should_replace = true

		if should_replace:
			best = {
				"blocked": blocked_cards,
				"pitched": pitched_cards,
				"prevention": prevention,
				"score": score,
				"survives": survives,
				"offense_after": offense_after,
				"damage_taken": damage_taken,
				"mask": mask,
				"cards_used": cards_used,
			}
			best_survives = survives
			best_score = score
			best_offense_after = offense_after
			best_cards_used = cards_used

	# Commit the chosen allocation. Block-card removal mirrors the old
	# defend() flow: arsenal is cleared by direct assignment; hand cards
	# emit card_removed_from_hand (drives _on_hand_changed -> recalc plan).
	# stats.block / stats.mana are applied here so that the AttackDamageEffect
	# / ZapEffect that fire immediately after defend_packet returns see the
	# right values when they call take_damage.
	var blocked_out: Array[Card] = best.get("blocked", [] as Array[Card])
	var pitched_out: Array[Card] = best.get("pitched", [] as Array[Card])
	print_enemy_ai("defend_packet pkt=(p:%d a:%d) hp=%d mana=%d picked mask=%s blocked=%d pitched=%d prevention=%d damage=%s survives=%s" % [
		physical, arcane, current_hp, current_mana, str(best.get("mask", -1)),
		blocked_out.size(), pitched_out.size(), int(best.get("prevention", 0)),
		str(best.get("damage_taken", -1)), str(best.get("survives", false))])
	for c: Card in blocked_out:
		var block_amount: int = modifier_handler.get_modified_value(c.defense, Modifier.Type.BLOCK_GAINED)
		enemy.stats.block += block_amount
		# Emit `blocked` directly (rather than calling card.block_card) so we
		# don't double-fire BlockEffect — the defense sequencer plays the block
		# SFX at badge-pop, staggered per card; routing through block_card here
		# would fire all SFX at once before the animations begin. The signal
		# emit still drives EnemyHandManager._on_card_blocked → exhaust pile.
		c.blocked.emit(c)
		if c == arsenal:
			arsenal = null
			print_enemy_ai("blocked arsenal %s for %d" % [c.id, block_amount])
		else:
			hand.erase(c)
			card_removed_from_hand.emit(c)
			print_enemy_ai("blocked %s for %d" % [c.id, block_amount])
	for c: Card in pitched_out:
		var pre_mana: int = enemy.stats.mana
		# pitch_card increments stats.mana AND emits `pitched`, which
		# EnemyHandManager._on_card_pitched routes to the discard pile.
		c.pitch_card(enemy.stats)
		var post_add_mana: int = enemy.stats.mana
		hand.erase(c)
		card_removed_from_hand.emit(c)
		print_enemy_ai("pitched %s defensively pre=%d +%d post_add=%d final=%d" % [c.id, pre_mana, c.pitch, post_add_mana, enemy.stats.mana])

	return {
		"blocked": blocked_out,
		"pitched": pitched_out,
		"prevention": int(best.get("prevention", 0)),
	}

## Recursively calculate maximum offense potential
##TODO: include damage modifiers
func calculate_max_offense(state: Dictionary, action_points: int, player_life: int) -> Dictionary:
	var arsenal_card = state.get("arsenal")
	if action_points <= 0 or (state.cards.size() == 0 and not arsenal_card):
		return {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards}

	var best_result = {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards.duplicate()}
	#lethal factor should be reworked to check if can present lethal
	var lethal_factor = 1#clamp(1.5 - (float(player_life) / 40.0), 1.0, 1.5)

	#Try pitching each card, make a new state, and then call it again.
	#Tie-break on equal damage by preferring fewer pitches — play_next_action
	#only pitches as needed at runtime, so over-pitching in the plan would
	#cause the displayed pitch list to disagree with what actually happens.
	#Note: arsenal cannot be pitched (F&B rule) — only carried through state.
	for pitch in state.cards:
		if pitch.disable_pitch:
			continue
		var new_state = {"cards": state.cards.duplicate(), "resources": state.resources + pitch.pitch, "arsenal": arsenal_card}
		new_state.cards.erase(pitch)
		var pitch_result = calculate_max_offense(new_state, action_points, player_life)
		var total_damage = pitch_result.damage * lethal_factor
		var new_pitched_size: int = 1 + pitch_result.pitched.size()
		if total_damage > best_result.damage or \
		   (total_damage > 0 and total_damage == best_result.damage and new_pitched_size < best_result.pitched.size()):
			best_result = {
				"damage": total_damage,
				"pitched": [pitch] + pitch_result.pitched,
				"actions": pitch_result.actions,
				"remaining": pitch_result.remaining
			}

	#Try current state — same fewer-pitches tie-break.
	var action_result = try_actions(state, action_points, player_life, lethal_factor)
	if action_result.damage > best_result.damage or \
	   (action_result.damage > 0 and action_result.damage == best_result.damage and action_result.pitched.size() < best_result.pitched.size()):
		best_result = action_result

	return best_result

##Helper for calculate_max_offense
##Calls with current hand, zero resources, and one action point
##Used at start of turn
func calculate_max_offense_now(player_life: int) -> Dictionary:
	var hand_state = {"cards": hand.duplicate(), "resources": 0, "arsenal": arsenal}
	return calculate_max_offense(hand_state, 1, player_life)
	
## Try playing actions with hand and resources defined in state
func try_actions(state: Dictionary, action_points: int, player_life: int, lethal_factor: float) -> Dictionary:
	var best_damage = 0
	var best_pitched = []
	var best_actions = []
	var best_remaining = state.cards.duplicate()

	var arsenal_card = state.get("arsenal")
	var candidates = state.cards.duplicate()
	if arsenal_card:
		candidates.append(arsenal_card)

	for action in candidates as Array[Card]:
		if action.unplayable:
			continue
		if action.cost <= state.resources and (action.type == Card.Type.ATTACK or action.type == Card.Type.NAA):
			var new_state: Dictionary
			if action == arsenal_card:
				new_state = {"cards": state.cards.duplicate(), "resources": state.resources - action.cost, "arsenal": null}
			else:
				new_state = {"cards": state.cards.duplicate(), "resources": state.resources - action.cost, "arsenal": arsenal_card}
				new_state.cards.erase(action)
			var next_ap = action_points - 1 + (1 if action.go_again else 0) + action.action_points_granted
			var sub_result = calculate_max_offense(new_state, next_ap, player_life)
			var current_action_damage_modified = modifier_handler.get_modified_value(action.attack, Modifier.Type.DMG_DEALT)
			var bonus = action.ai_value
			if action.ai_value_needs_attack and not sub_result.actions.any(func(c): return c.type == Card.Type.ATTACK):
				bonus = 0
			current_action_damage_modified += bonus
			var total_damage = (current_action_damage_modified + sub_result.damage) * lethal_factor
			
			if total_damage > best_damage or \
			   (total_damage > 0 and total_damage == best_damage and sub_result.pitched.size() < best_pitched.size()):
				best_damage = total_damage
				best_pitched = sub_result.pitched
				best_actions = [action] + sub_result.actions
				best_remaining = sub_result.remaining
	
	return {"damage": best_damage, "pitched": best_pitched, "actions": best_actions, "remaining": best_remaining}

## Pick the best card to arsenal
func pick_best_arsenal(cards: Array) -> Card:
	var eligible: Array = cards.filter(func(c): return not c.unplayable)
	if eligible.size() == 0:
		return null
	var best_card = eligible[0]
	for card in eligible:
		if card.type == Card.Type.BLOCK:
			if best_card.type != Card.Type.BLOCK:
				best_card = card
			elif card.defense > best_card.defense:
				best_card = card
		elif card.pitch < best_card.pitch:
			best_card = card
		elif card.pitch == best_card.pitch:
			if (card.attack + card.ai_value) > (best_card.attack + best_card.ai_value):
				best_card = card
	return best_card

##Draw back up to full
#func end_turn() -> void:
	#Should recycle pitch here instead of instantly sending it to the bottom
	#for i in enemy.stats.cards_per_turn - hand.size():
		#var temp_card: Card = enemy.stats.draw_pile.draw_card()
		#if temp_card:
			#hand.append(temp_card)

func print_enemy_ai(debug_str: String) -> void:
				print("%s %s: %s" % [enemy.stats.character_name, enemy.name, debug_str])
