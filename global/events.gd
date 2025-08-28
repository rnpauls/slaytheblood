extends Node


#Card-related events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(card_ui: CardUI)
signal card_aim_ended(card_ui: CardUI)
signal card_played(card: CardUI)
signal card_pitched(card: CardUI)
signal card_tooltip_requested(icon: Texture, text: String)
signal tooltip_hide_requested

#Player-related events
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_end_phase_started
signal player_hit
signal player_died
signal player_card_drawn
signal player_action_phase_started
signal player_blocks_declared

#Enemy-related events
signal enemy_turn_completed(enemy: Enemy) #curently called when enemy is done with all actions, and statuses should be activated to move to next enemy
signal enemy_phase_ended #Called when all enemies are done, move to player turn
signal enemy_died(enemy: Enemy)
signal enemy_attack_declared

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
