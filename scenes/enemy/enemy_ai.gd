class_name EnemyAI
extends Node

var enemy: Enemy # Reference to enemy object (with life, intellect)
#var deck: CardPile # Array of card objects (Card class)
var hand: Array = [] # Current hand
#var life: int
var arsenal = null # Single Card or null
var turn_plan = null # Stores the planned turn {damage, pitched, actions, remaining}
var resources = 0 # Tracks resources available this turn

@export var target: Node2D#: set = _set_target

signal plan_created(enemy: Enemy)

func setup():
	target = get_tree().get_first_node_in_group("player")
	 #= deck_data.duplicate()
	#life = enemy.stats.health
	for i in enemy.stats.cards_per_turn:
		hand.append(enemy.stats.draw_pile.draw_card())
# Start the AI's turn by planning actions
func start_turn(player_life: int) -> void:
	var hand_state = {"cards": hand.duplicate(), "resources": 0}
	turn_plan = calculate_max_offense(hand_state, 1, player_life)
	resources = 0
	plan_created.emit(enemy)

# Play the next action, returns card to the enemy node
func play_next_action() -> Card:
	if not turn_plan or turn_plan.actions.size() == 0:
		if turn_plan and turn_plan.remaining.size() > 0 and not arsenal:
			arsenal = pick_best_arsenal(turn_plan.remaining)
			hand.erase(arsenal)
			print_enemy_ai("arsenaled %s" % arsenal.id)
		turn_plan = null
		return null
	
	var next_action = turn_plan.actions[0]
	
	while resources < next_action.cost and turn_plan.pitched.size() > 0:
		var pitch = turn_plan.pitched[0]
		resources += pitch.pitch
		enemy.stats.draw_pile.add_card(pitch)
		hand.erase(pitch)
		turn_plan.pitched.erase(pitch)
		print_enemy_ai("pitched %s for %d" % [pitch.id, pitch.pitch])
	
	if resources < next_action.cost:
		turn_plan.actions.erase(next_action)
		print_enemy_ai("ran out of resources for %s" % next_action.id)
		return null
	
	resources -= next_action.cost
	hand.erase(next_action)
	turn_plan.actions.erase(next_action)
	print_enemy_ai("played %s" % [next_action.id])
	return next_action

# Defending phase: Player attacks AI, returns array of defense values
func defend(player_attack_power: int, has_go_again: bool, player_hand_size) -> Array:
	var hand_state = {"cards": hand.duplicate(), "resources": 0}
	var max_offense = calculate_max_offense(hand_state, 1, enemy.stats.health)["damage"]
	var block_options = calculate_block_options(hand_state, player_attack_power, has_go_again, player_hand_size)
	
	# Life factor: More blocking when life is low (0.5 at 20+, 2.0 at 5 or less)
	var life_factor = clamp(2.0 - (float(enemy.stats.health) / 20.0), 0.5, 2.0)
	var best_option = {"defense_applied": [], "offense_lost": max_offense, "damage_taken": player_attack_power, "raw_damage": max_offense}
	
	# Force blocking if attack is lethal
	var is_lethal = player_attack_power >= enemy.stats.health
	
	for option in block_options:
		var damage_taken = max(0, player_attack_power - option.defense)
		var offense_lost = max_offense - option.offense_after
		var score = (damage_taken * life_factor) + offense_lost
		
		# Block lethal damage regardless of score
		if is_lethal and damage_taken == 0:
			best_option = {"defense_applied": option.defense_applied, "offense_lost": offense_lost, "damage_taken": damage_taken, "raw_damage": option.offense_after}
			break
		# Normal comparison with tiebreaker on raw damage
		if not is_lethal and (score < (best_option.damage_taken * life_factor + best_option.offense_lost) or \
		   (score == (best_option.damage_taken * life_factor + best_option.offense_lost) and option.offense_after > best_option.raw_damage)):
			best_option = {"defense_applied": option.defense_applied, "offense_lost": offense_lost, "damage_taken": damage_taken, "raw_damage": option.offense_after}
	
	for block in best_option.defense_applied:
		#Does this actually work? Checking if it equals the arsenal card?
		if block.card == arsenal:
			print_enemy_ai("blocked arsenal %s for %d" % [block.card.id, block.card.defense])
			arsenal = null
		else:
			print_enemy_ai("blocked %s for %d" % [block.card.id, block.card.defense])
			hand.erase(block.card)
	return best_option.defense_applied.map(func(c): return c.defense) if best_option.defense_applied else []

# Recursively calculate maximum offense potential
#TODO: include damage modifiers
func calculate_max_offense(state: Dictionary, action_points: int, player_life: int) -> Dictionary:
	if action_points <= 0 or state.cards.size() == 0:
		return {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards}
	
	var best_result = {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards.duplicate()}
	var lethal_factor = clamp(1.5 - (float(player_life) / 40.0), 1.0, 1.5)
	
	for pitch in state.cards:
		var new_state = {"cards": state.cards.duplicate(), "resources": state.resources + pitch.pitch}
		new_state.cards.erase(pitch)
		var pitch_result = calculate_max_offense(new_state, action_points, player_life)
		var total_damage = pitch_result.damage * lethal_factor
		if total_damage > best_result.damage or \
		   (total_damage == best_result.damage and pitch_result.damage > best_result.damage / lethal_factor):
			best_result = {
				"damage": total_damage,
				"pitched": [pitch] + pitch_result.pitched,
				"actions": pitch_result.actions,
				"remaining": pitch_result.remaining
			}
	
	var action_result = try_actions(state, action_points, player_life, lethal_factor)
	if action_result.damage > best_result.damage or \
	   (action_result.damage == best_result.damage and action_result.damage / lethal_factor > best_result.damage / lethal_factor):
		best_result = action_result
	
	return best_result

# Try playing actions with current resources
func try_actions(state: Dictionary, action_points: int, player_life: int, lethal_factor: float) -> Dictionary:
	var best_damage = 0
	var best_pitched = []
	var best_actions = []
	var best_remaining = state.cards.duplicate()
	
	for action in state.cards:
		if action.cost <= state.resources and (action.type == Card.Type.ATTACK or action.type == Card.Type.NAA):
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources - action.cost}
			new_state.cards.erase(action)
			var next_ap = action_points - 1 + (1 if action.go_again else 0)
			var sub_result = calculate_max_offense(new_state, next_ap, player_life)
			var total_damage = (action.attack + sub_result.damage) * lethal_factor
			
			if total_damage > best_damage or \
			   (total_damage == best_damage and (action.attack + sub_result.damage) > (best_damage / lethal_factor)):
				best_damage = total_damage
				best_pitched = sub_result.pitched
				best_actions = [action] + sub_result.actions
				best_remaining = sub_result.remaining
	
	return {"damage": best_damage, "pitched": best_pitched, "actions": best_actions, "remaining": best_remaining}

# Recursively calculate blocking options with Go Again heuristic
func calculate_block_options(state: Dictionary, attack_power: int, has_go_again: bool, player_hand_size: int) -> Array:
	var options = [{"defense": 0, "defense_applied": [], "offense_after": calculate_max_offense(state, 1, enemy.stats.health)["damage"]}]
	
	if attack_power > 0:
		for card in state.cards:
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources}
			new_state.cards.erase(card)
			var defense = card.defense
			var remaining_attack = attack_power - defense
			var sub_options = calculate_block_options(new_state, remaining_attack, has_go_again, player_hand_size)
			
			for sub in sub_options:
				var total_defense = defense + sub.defense
				var applied = [{"card": card, "defense": defense}] + sub.defense_applied
				var offense_after = sub.offense_after
				if has_go_again and remaining_attack <= 0:
					var second_attack = player_hand_size * 3 # Heuristic: 3 damage per card
					var go_again_state = {"cards": new_state.cards.duplicate(), "resources": new_state.resources}
					var second_options = calculate_block_options(go_again_state, second_attack, false, 0)
					var best_second = second_options[0]
					for opt in second_options:
						if (second_attack - opt.defense) + opt.offense_after < (second_attack - best_second.defense) + best_second.offense_after:
							best_second = opt
					offense_after = best_second.offense_after
				options.append({"defense": total_defense, "defense_applied": applied, "offense_after": offense_after})
		
		if arsenal and arsenal.type == Card.Type.BLOCK:
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources}
			var defense = arsenal.defense
			var remaining_attack = attack_power - defense
			var sub_options = calculate_block_options(new_state, remaining_attack, has_go_again, player_hand_size)
			
			for sub in sub_options:
				var total_defense = defense + sub.defense
				var applied = [{"card": arsenal, "defense": defense}] + sub.defense_applied
				var offense_after = sub.offense_after
				if has_go_again and remaining_attack <= 0:
					var second_attack = player_hand_size * 3
					var go_again_state = {"cards": new_state.cards.duplicate(), "resources": new_state.resources}
					var second_options = calculate_block_options(go_again_state, second_attack, false, 0)
					var best_second = second_options[0]
					for opt in second_options:
						if (second_attack - opt.defense) + opt.offense_after < (second_attack - best_second.defense) + best_second.offense_after:
							best_second = opt
					offense_after = best_second.offense_after
				options.append({"defense": total_defense, "defense_applied": applied, "offense_after": offense_after})
	
	return options

# Pick the best card to arsenal
func pick_best_arsenal(cards: Array) -> Card:
	if cards.size() == 0:
		return null
	var best_card = cards[0]
	for card in cards:
		if card.type == Card.Type.BLOCK and best_card.type != Card.Type.BLOCK:
			best_card = card
		elif card.type == best_card.type:
			if card.defense > best_card.defense or \
			   (card.defense == best_card.defense and card.attack > best_card.attack):
				best_card = card
	return best_card

func end_turn() -> void:
	#Should recycle pitch here instead of instantly sending it to the bottom
	for i in enemy.stats.cards_per_turn - hand.size():
		var temp_card: Card = enemy.stats.draw_pile.draw_card()
		if temp_card:
			hand.append(temp_card)

func print_enemy_ai(debug_str: String) -> void:
				print("%s %s: %s" % [enemy.stats.character_name, enemy.name, debug_str])
