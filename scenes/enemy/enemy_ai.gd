class_name EnemyAI
extends Node

var enemy: Enemy # Reference to enemy object
var hand: Array[CardUI] = [] # Now holds CardUI nodes
var arsenal: CardUI = null # Now CardUI
var turn_plan = null # Stores the planned turn {damage, pitched, actions, remaining}
var resources := 0 # Tracks resources available this turn
var modifier_handler: ModifierHandler

@export var target: Node2D

signal plan_created(enemy: Enemy)

## Just assigns the player as target
func setup():
	target = get_tree().get_first_node_in_group("player")

## Start the AI's turn by planning actions
func start_turn(player_life: int) -> void:
	turn_plan = calculate_max_offense_now(player_life)
	resources = 0
	plan_created.emit(enemy)

## Play the next action in turn_plan, returns CardUI to the enemy node
## Pitches cards as needed
## Arsenals if out of actions
func play_next_action() -> CardUI:
	if not turn_plan or turn_plan.actions.size() == 0:
		if turn_plan and turn_plan.remaining.size() > 0 and not arsenal:
			arsenal = pick_best_arsenal(turn_plan.remaining)
			if arsenal:
				hand.erase(arsenal)
				print_enemy_ai("arsenaled %s" % arsenal.card.id)
		turn_plan = null
		return null
	
	var next_action: CardUI = turn_plan.actions[0]
	
	while resources < next_action.card.cost and turn_plan.pitched.size() > 0:
		var pitch: CardUI = turn_plan.pitched[0]
		resources += pitch.card.pitch
		enemy.stats.draw_pile.add_card(pitch.card)
		hand.erase(pitch)
		turn_plan.pitched.erase(pitch)
		print_enemy_ai("pitched %s for %d" % [pitch.card.id, pitch.card.pitch])
	
	if resources < next_action.card.cost:
		turn_plan.actions.erase(next_action)
		print_enemy_ai("ran out of resources for %s" % next_action.card.id)
		return null
	
	resources -= next_action.card.cost
	hand.erase(next_action)
	turn_plan.actions.erase(next_action)
	print_enemy_ai("played %s" % [next_action.card.id])
	return next_action

## Defending phase: Player attacks AI, returns array of CardUI for blocking
func defend(player_attack_power: int, has_go_again: bool, onhits: Array[OnHit]) -> Array[CardUI]:
	var player_hand_size : int = target.get_tree().get_first_node_in_group("player_hand").get_child_count()
	var hand_state = {"cards": hand.duplicate(), "resources": 0}
	var max_offense = calculate_max_offense(hand_state, 1, enemy.stats.health)["damage"]
	var modified_damage = modifier_handler.get_modified_value(player_attack_power, Modifier.Type.DMG_TAKEN)
	var block_options = calculate_block_options(hand_state, modified_damage, has_go_again, player_hand_size, onhits)
	
	var life_factor = 1
	var best_option = {"defense_applied": [], "offense_lost": max_offense, "damage_taken": modified_damage, "raw_damage": max_offense}
	
	for option in block_options:
		var damage_taken = max(0, modified_damage - option.defense)
		var offense_lost = max_offense - option.offense_after
		var score = (damage_taken * life_factor) + offense_lost
		
		if (score < (best_option.damage_taken * life_factor + best_option.offense_lost) or \
		   (score == (best_option.damage_taken * life_factor + best_option.offense_lost) and option.offense_after > best_option.raw_damage)):
			best_option = {"defense_applied": option.defense_applied, "offense_lost": offense_lost, "damage_taken": damage_taken, "raw_damage": option.offense_after}
	
	var blocking_cards: Array[CardUI]
	for block in best_option.defense_applied:
		if block.card == arsenal:  # Note: block.card here is the inner dict key
			print_enemy_ai("blocked arsenal %s for %d" % [block.card.id, block.card.defense])
			arsenal = null
			blocking_cards.append(arsenal)  # Wait — this was a bug in original; fixed to append the actual CardUI
		else:
			print_enemy_ai("blocked %s for %d" % [block.card.id, block.card.defense])
			hand.erase(block.card_ui)  # block now contains the CardUI reference (see calculate_block_options)
			blocking_cards.append(block.card_ui)
	return blocking_cards

## Recursively calculate maximum offense potential
func calculate_max_offense(state: Dictionary, action_points: int, player_life: int) -> Dictionary:
	if action_points <= 0 or state.cards.size() == 0:
		return {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards}
	
	var best_result = {"damage": 0, "pitched": [], "actions": [], "remaining": state.cards.duplicate()}
	var lethal_factor = 1
	
	# Try pitching each card
	for pitch: CardUI in state.cards:
		var new_state = {"cards": state.cards.duplicate(), "resources": state.resources + pitch.card.pitch}
		new_state.cards.erase(pitch)
		var pitch_result = calculate_max_offense(new_state, action_points, player_life)
		var total_damage = pitch_result.damage * lethal_factor
		if total_damage > best_result.damage:
			best_result = {
				"damage": total_damage,
				"pitched": [pitch] + pitch_result.pitched,
				"actions": pitch_result.actions,
				"remaining": pitch_result.remaining
			}
	
	# Try playing actions
	var action_result = try_actions(state, action_points, player_life, lethal_factor)
	if action_result.damage > best_result.damage or \
	   (action_result.damage == best_result.damage and action_result.damage / lethal_factor > best_result.damage / lethal_factor):
		best_result = action_result
	
	return best_result

## Helper for calculate_max_offense
func calculate_max_offense_now(player_life: int) -> Dictionary:
	var hand_state = {"cards": hand.duplicate(), "resources": 0}
	return calculate_max_offense(hand_state, 1, player_life)
	
## Try playing actions with hand and resources defined in state
func try_actions(state: Dictionary, action_points: int, player_life: int, lethal_factor: float) -> Dictionary:
	var best_damage = 0
	var best_pitched = []
	var best_actions = []
	var best_remaining = state.cards.duplicate()
	
	for action: CardUI in state.cards:
		if action.card.cost <= state.resources and (action.card.type == Card.Type.ATTACK or action.card.type == Card.Type.NAA):
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources - action.card.cost}
			new_state.cards.erase(action)
			var next_ap = action_points - 1 + (1 if action.card.go_again else 0)
			var sub_result = calculate_max_offense(new_state, next_ap, player_life)
			var current_action_damage_modified = modifier_handler.get_modified_value(action.card.attack, Modifier.Type.DMG_DEALT)
			current_action_damage_modified += action.card.ai_value
			var total_damage = (current_action_damage_modified + sub_result.damage) * lethal_factor
			
			if total_damage > best_damage:
				best_damage = total_damage
				best_pitched = sub_result.pitched
				best_actions = [action] + sub_result.actions
				best_remaining = sub_result.remaining
	
	return {"damage": best_damage, "pitched": best_pitched, "actions": best_actions, "remaining": best_remaining}

## Recursively calculate blocking options with Go Again heuristic
func calculate_block_options(state: Dictionary, attack_power: int, has_go_again: bool, player_hand_size: int, onhits: Array[OnHit]) -> Array:
	var options = [{"defense": 0, "defense_applied": [], "offense_after": calculate_max_offense(state, 1, enemy.stats.health)["damage"]}]
	
	if attack_power > 0:
		for card_ui: CardUI in state.cards:
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources}
			new_state.cards.erase(card_ui)
			var defense = card_ui.card.defense
			var remaining_attack = attack_power - defense
			var sub_options = calculate_block_options(new_state, remaining_attack, has_go_again, player_hand_size, onhits)
			
			for sub in sub_options:
				var total_defense = defense + sub.defense
				var applied = [{"card": card_ui.card, "defense": defense, "card_ui": card_ui}] + sub.defense_applied
				var offense_after = sub.offense_after
				# Go Again logic (unchanged except for .card access)
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
					if onhits and (attack_power <= total_defense):
						for tmp_onhit in onhits:
							offense_after += tmp_onhit.ai_value
					options.append({"defense": total_defense, "defense_applied": applied, "offense_after": offense_after})
		
		# Arsenal blocking (unchanged logic, updated for CardUI)
		if arsenal and arsenal.card.type == Card.Type.BLOCK:
			# ... (same pattern as above — I kept the original structure for arsenal)
			var new_state = {"cards": state.cards.duplicate(), "resources": state.resources}
			var defense = arsenal.card.defense
			var remaining_attack = attack_power - defense
			var sub_options = calculate_block_options(new_state, remaining_attack, has_go_again, player_hand_size, onhits)
			
			for sub in sub_options:
				var total_defense = defense + sub.defense
				var applied = [{"card": arsenal.card, "defense": defense, "card_ui": arsenal}] + sub.defense_applied
				var offense_after = sub.offense_after
				if has_go_again and remaining_attack <= 0:
					# same go_again logic
					var second_attack = player_hand_size * 3
					var go_again_state = {"cards": new_state.cards.duplicate(), "resources": new_state.resources}
					var second_options = calculate_block_options(go_again_state, second_attack, false, 0, [])
					var best_second = second_options[0]
					for opt in second_options:
						if (second_attack - opt.defense) + opt.offense_after < (second_attack - best_second.defense) + best_second.offense_after:
							best_second = opt
					offense_after = best_second.offense_after
				if attack_power - total_defense < enemy.stats.health:
					if onhits and (attack_power <= total_defense):
						for tmp_onhit in onhits:
							offense_after += tmp_onhit.ai_value
					options.append({"defense": total_defense, "defense_applied": applied, "offense_after": offense_after})
	
	if (attack_power >= enemy.stats.health) and (options.size() > 1):
		options.remove_at(0)
	return options

## Pick the best card to arsenal
func pick_best_arsenal(cards: Array[CardUI]) -> CardUI:
	if cards.size() == 0:
		return null
	var best_card: CardUI = cards[0]
	for card_ui: CardUI in cards:
		var card = card_ui.card
		if card.type == Card.Type.BLOCK:
			if best_card.card.type != Card.Type.BLOCK:
				best_card = card_ui
			elif card.defense > best_card.card.defense:
				best_card = card_ui
		elif card.pitch < best_card.card.pitch:
			best_card = card_ui
		elif card.pitch == best_card.card.pitch:
			if (card.attack + card.ai_value) > (best_card.card.attack + best_card.card.ai_value):
				best_card = card_ui
	return best_card

func print_enemy_ai(debug_str: String) -> void:
	print("%s %s: %s" % [enemy.stats.character_name, enemy.name, debug_str])
