class_name EnemyAI
extends Node

var enemy: Enemy # Reference to enemy object (with life, intellect)
#var deck: CardPile # Array of card objects (Card class)
var hand: Array # Current hand
#var life: int
var arsenal: Card = null # Single Card or null
var turn_plan = null # Stores the planned turn {damage, pitched, actions, remaining}
var resources := 0 # Tracks resources available this turn
## Cards that cannot be used to block this turn due to Intimidate. Set by IntimidatedStatus.
var intimidated_cards: Array[Card] = []

@export var target: Node2D#: set = _set_target

signal plan_created(enemy: Enemy)
## Emitted whenever the AI removes a card from its hand (pitch, play, block, arsenal).
## Enemy.gd connects to this to keep the visual hand in sync.
signal card_removed_from_hand(card: Card)

## Just assigns the player as target
func setup():
	target = get_tree().get_first_node_in_group("player")
	 #= deck_data.duplicate()
	#life = enemy.stats.health
	#for i in enemy.stats.cards_per_turn:
		#hand.append(enemy.stats.draw_pile.draw_card())

## Start the AI's turn by planning actions
func start_turn(player_life: int) -> void:
	turn_plan = calculate_max_offense_now(player_life)
	resources = 0
	plan_created.emit(enemy)

## Play the next action in turn_plan, returns card to the enemy node
## Pitches cards as needed
## Arsenals if out of actions
func play_next_action() -> Card:
	if not turn_plan or turn_plan.actions.size() == 0:
		if turn_plan and turn_plan.remaining.size() > 0 and not arsenal:
			arsenal = pick_best_arsenal(turn_plan.remaining)
			hand.erase(arsenal)
			card_removed_from_hand.emit(arsenal)
			print_enemy_ai("arsenaled %s" % arsenal.id)
		turn_plan = null
		return null
	
	var next_action = turn_plan.actions[0]
	
	while resources < next_action.cost and turn_plan.pitched.size() > 0:
		var pitch = turn_plan.pitched[0]
		resources += pitch.pitch
		enemy.stats.draw_pile.add_card(pitch)
		hand.erase(pitch)
		card_removed_from_hand.emit(pitch)
		turn_plan.pitched.erase(pitch)
		print_enemy_ai("pitched %s for %d" % [pitch.id, pitch.pitch])
	
	if resources < next_action.cost:
		turn_plan.actions.erase(next_action)
		print_enemy_ai("ran out of resources for %s" % next_action.id)
		return null
	
	resources -= next_action.cost
	hand.erase(next_action)
	card_removed_from_hand.emit(next_action)
	turn_plan.actions.erase(next_action)
	print_enemy_ai("played %s" % [next_action.id])
	return next_action

## Defending phase: Player attacks AI, returns array of defense values
func defend(player_attack_power: int, has_go_again: bool, onhits: Array[OnHit]) -> Array[Card]:
	var player_hand_size : int = target.get_tree().get_first_node_in_group("player_hand").get_child_count()
	var hand_state = {"cards": hand.duplicate(), "resources": 0}
	var max_offense = calculate_max_offense(hand_state, 1, enemy.stats.health)["damage"]
	var modified_damage = Hook.get_damage(target, enemy, player_attack_power)
	var block_options = calculate_block_options(hand_state, modified_damage, has_go_again, player_hand_size, onhits)
	
	# Life factor: More blocking when life is low (0.5 at 20+, 2.0 at 5 or less)
	var life_factor = 1#clamp(2.0 - (float(enemy.stats.health) / 20.0), 0.5, 2.0)
	var best_option = {"defense_applied": [], "offense_lost": max_offense, "damage_taken": modified_damage, "raw_damage": max_offense}
	
	# Force blocking if attack is lethal
	#var is_lethal = modified_damage >= enemy.stats.health
	
	for option in block_options:
		var damage_taken = max(0, modified_damage - option.defense)
		var offense_lost = max_offense - option.offense_after
		var score = (damage_taken * life_factor) + offense_lost
		
		# Block lethal damage regardless of score
		#if is_lethal and damage_taken == 0:
			#best_option = {"defense_applied": option.defense_applied, "offense_lost": offense_lost, "damage_taken": damage_taken, "raw_damage": option.offense_after}
			#break
		# Normal comparison with tiebreaker on raw damage
		if (score < (best_option.damage_taken * life_factor + best_option.offense_lost) or \
		   (score == (best_option.damage_taken * life_factor + best_option.offense_lost) and option.offense_after > best_option.raw_damage)):
			best_option = {"defense_applied": option.defense_applied, "offense_lost": offense_lost, "damage_taken": damage_taken, "raw_damage": option.offense_after}
	
	var blocking_cards: Array[Card]
	for block in best_option.defense_applied:
		#Does this actually work? Checking if it equals the arsenal card?
		if block.card == arsenal:
			print_enemy_ai("blocked arsenal %s for %d" % [block.card.id, block.card.defense])
			var used_arsenal := arsenal
			arsenal = null
			blocking_cards.append(used_arsenal)
		else:
			print_enemy_ai("blocked %s for %d" % [block.card.id, block.card.defense])
			hand.erase(block.card)
			card_removed_from_hand.emit(block.card)
			blocking_cards.append(block.card)
	return blocking_cards#best_option.defense_applied.map(func(c): return c.defense) if best_option.defense_applied else []

## Recursively calculate maximum offense potential
##TODO: include damage modifiers
func calculate_max_offense(state: Dictionary, action_points: int, player_life: int) -> Dictionary:
	if action_points <= 0 or state.cards.size() == 0:
		return {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards}
	
	var best_result = {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards.duplicate()}
	#lethal factor should be reworked to check if can present lethal
	var lethal_factor = 1#clamp(1.5 - (float(player_life) / 40.0), 1.0, 1.5)
	
	#Try pitching each card, make a new state, and then call it again
	for pitch in state.cards:
		var new_state = {"cards": state.cards.duplicate(), "resources": state.resources + pitch.pitch}
		new_state.cards.erase(pitch)
		var pitch_result = calculate_max_offense(new_state, action_points, player_life)
		var total_damage = pitch_result.damage * lethal_factor
		if total_damage > best_result.damage:# or \
		   #(total_damage == best_result.damage and pitch_result.damage > best_result.damage / lethal_factor):
			best_result = {
				"damage": total_damage,
				"pitched": [pitch] + pitch_result.pitched,
				"actions": pitch_result.actions,
				"remaining": pitch_result.remaining
			}
	
	#Try current state
	var action_result = try_actions(state, action_points, player_life, lethal_factor)
	if action_result.damage > best_result.damage or \
	   (action_result.damage == best_result.damage and action_result.damage / lethal_factor > best_result.damage / lethal_factor):
		best_result = action_result
	
	return best_result

##Helper for calculate_max_offense
##Calls with current hand, zero resources, and one action point
##Used at start of turn
func calculate_max_offense_now(player_life: int) -> Dictionary:
	var hand_state = {"cards": hand.duplicate(), "resources": 0}
	return calculate_max_offense(hand_state, 1, player_life)
	
## Try playing actions with hand and resources defined in state
func try_actions(state: Dictionary, action_points: int, player_life: int, lethal_factor: float) -> Dictionary:
	var best_damage = 0
	var best_pitched = []
	var best_actions = []
	var best_remaining = state.cards.duplicate()
	
	for action in state.cards as Array[Card]:
		if action.cost <= state.resources and (action.type == Card.Type.ATTACK or action.type == Card.Type.NAA):
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources - action.cost}
			new_state.cards.erase(action)
			var next_ap = action_points - 1 + (1 if action.go_again else 0)
			var sub_result = calculate_max_offense(new_state, next_ap, player_life)
			var current_action_damage_modified = Hook.get_damage(enemy, target, action.attack)
			current_action_damage_modified += action.ai_value
			var total_damage = (current_action_damage_modified + sub_result.damage) * lethal_factor
			
			if total_damage > best_damage:# or \
			   #(total_damage == best_damage and (action.attack + sub_result.damage) > (best_damage / lethal_factor)):
				best_damage = total_damage
				best_pitched = sub_result.pitched
				best_actions = [action] + sub_result.actions
				best_remaining = sub_result.remaining
	
	return {"damage": best_damage, "pitched": best_pitched, "actions": best_actions, "remaining": best_remaining}

## Recursively calculate blocking options with Go Again heuristic
func calculate_block_options(state: Dictionary, attack_power: int, has_go_again: bool, player_hand_size: int, onhits: Array[OnHit]) -> Array:
	var options = [{"defense": 0, "defense_applied": [], "offense_after": calculate_max_offense(state, 1, enemy.stats.health)["damage"]}]
	
	if attack_power > 0:
		for card in state.cards:
			# Skip cards that are intimidated — they cannot be used to block this turn.
			if card in intimidated_cards:
				continue
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources}
			new_state.cards.erase(card)
			var defense = card.defense
			var remaining_attack = attack_power - defense
			var sub_options = calculate_block_options(new_state, remaining_attack, has_go_again, player_hand_size, onhits)
			
			for sub in sub_options:
				var total_defense = defense + sub.defense
				var applied = [{"card": card, "defense": defense}] + sub.defense_applied
				var offense_after = sub.offense_after
				if has_go_again and remaining_attack <= 0:
					var second_attack = player_hand_size * 3 # Heuristic: 3 damage per card
					var go_again_state = {"cards": new_state.cards.duplicate(), "resources": new_state.resources}
					var second_options = calculate_block_options(go_again_state, second_attack, false, 0, [])
					var best_second = second_options[0]
					for opt in second_options:
						if (second_attack - opt.defense) + opt.offense_after < (second_attack - best_second.defense) + best_second.offense_after:
							best_second = opt
					offense_after = best_second.offense_after
				if attack_power - total_defense < enemy.stats.health:
					if (onhits) and (attack_power <= total_defense): #If theres an on-hit and the attack is fully blocked
						for tmp_onhit in onhits:
							offense_after += tmp_onhit.ai_value #Add the expected value of the on-hit to the offense value
					options.append({"defense": total_defense, "defense_applied": applied, "offense_after": offense_after})
		
		if arsenal and arsenal.type == Card.Type.BLOCK:
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources}
			var defense = arsenal.defense
			var remaining_attack = attack_power - defense
			var sub_options = calculate_block_options(new_state, remaining_attack, has_go_again, player_hand_size, onhits)
			
			for sub in sub_options:
				var total_defense = defense + sub.defense
				var applied = [{"card": arsenal, "defense": defense}] + sub.defense_applied
				var offense_after = sub.offense_after
				if has_go_again and remaining_attack <= 0:
					var second_attack = player_hand_size * 3
					var go_again_state = {"cards": new_state.cards.duplicate(), "resources": new_state.resources}
					var second_options = calculate_block_options(go_again_state, second_attack, false, 0, [])
					var best_second = second_options[0]
					for opt in second_options:
						if (second_attack - opt.defense) + opt.offense_after < (second_attack - best_second.defense) + best_second.offense_after:
							best_second = opt
					offense_after = best_second.offense_after
				if attack_power - total_defense < enemy.stats.health:
					if (onhits) and (attack_power <= total_defense): #If theres an on-hit and the attack is fully blocked
						for tmp_onhit in onhits:
							offense_after += tmp_onhit.ai_value #Add the expected value of the on-hit to the offense value
					options.append({"defense": total_defense, "defense_applied": applied, "offense_after": offense_after})
	#Remove original non-blocking option if lethal
	if (attack_power >= enemy.stats.health) and (options.size() > 1):
		options.remove_at(0)
	return options

## Pick the best card to arsenal
func pick_best_arsenal(cards: Array) -> Card:
	if cards.size() == 0:
		return null
	var best_card = cards[0]
	for card in cards:
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
