extends Node


#Card-related events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(origin: Node)
signal card_aim_ended(origin: Node)
#signal card_played(card: Card)
signal card_discarded(card: Card)
signal card_pitched(card: Card)
signal card_sunk(card: Card)
signal card_blocked(card: Card)
#signal card_milled(card: CardUI)
signal card_tooltip_requested(icon: Texture, text: String)
signal tooltip_hide_requested
signal selecting_cards_from_hand
signal finished_selecting_cards_from_hand(selected_cards: Array[CardUI])
signal lock_hand()
signal unlock_hand()

#Player-related events
signal player_initial_hand_drawn
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_end_phase_started
signal player_hit
signal player_died
signal player_card_drawn
signal player_action_phase_started
signal player_blocks_declared
signal player_set_up #emitted once the player is initialized in the battle
signal player_attack_declared
signal player_attack_completed

#Enemy-related events
signal enemy_turn_completed(enemy: Enemy) #curently called when enemy is done with all actions, and statuses should be activated to move to next enemy
signal enemy_phase_ended #Called when all enemies are done, move to player turn
signal enemy_died(enemy: Enemy)
signal enemy_attack_declared
signal enemy_card_drawn(enemy: Enemy)
## Emitted when an enemy stages its attack card to the center of the screen
signal attack_card_staged(card_ui: EnemyCardUI)
## Emitted when the staged card should be removed (attack resolved or enemy died)
signal attack_card_unstaged
## Emitted when the player hovers the intent UI (used for on-hit tooltip)
signal intent_hovered(enemy: Enemy)
signal intent_unhovered(enemy: Enemy)
#Battle-related events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])

# Map-related events
signal map_exited(room: Room)

# Shop-related events
signal shop_entered(shop: Shop)
signal shop_relic_bought(relic: Relic, gold_cost: int)
signal shop_card_bought(card: Card, gold_cost: int)
signal shop_weapon_bought(weapon: Weapon, gold_cost: int)
signal shop_equipment_bought(equipment: Equipment, gold_cost: int)
signal shop_exited

#Campfire-related events
signal campfire_exited

# Battle Reward-related events
signal battle_reward_exited

# Treasure Room-related events
signal treasure_room_exited(found_relic: Relic)

# Relic-related events
signal relic_tooltip_requested(relic: Relic)

#Random Event room-related events
signal event_room_exited
