extends Node


#Card-related events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(origin: Node)
signal card_aim_ended(origin: Node)
signal card_discarded(card: Card)
signal card_pitched(card: Card)
signal card_sunk(card: Card)
signal card_blocked(card: Card)
signal card_exhausted(card: Card)

## Fires after a physical attack lands and damage is actually applied. Carries
## attacker reference so reactive effects (Bloodied Pelt's "first time hit",
## healing-on-damage relics, etc.) can target the source. Skipped for fully
## blocked attacks — use combatant_attacked for "you were targeted" reactions.
## Reflect-style effects should use a plain DamageEffect to avoid re-firing
## this signal infinitely.
signal combatant_damaged(victim: Node, attacker: Node, damage: int)
## Fires for EVERY physical attack against a combatant — including ones that
## block fully absorbs (where damage_dealt is 0). Used by reactive defenders
## that punish the attempt rather than the damage (Thorns, Spiked Pauldrons).
## `attempted` is the pre-block amount; `damage_dealt` is the post-block
## residual that actually hit health.
signal combatant_attacked(victim: Node, attacker: Node, attempted: int, damage_dealt: int)
## Show one or more tooltip boxes (e.g. main card description + one box per
## keyword). Pass anchor_rect in canvas/global coords to anchor next to a source
## (right-of-source, flips left); pass Rect2() to anchor to the mouse instead.
signal tooltip_show_requested(entries: Array[TooltipData], anchor_rect: Rect2)
signal tooltip_hide_requested
## Owner-tagged variants for sources that fire show/hide in racy cross-frame
## orderings (e.g. Area2D + Control siblings on the same enemy). The TooltipLayer
## tracks the current owner_id; a hide is honored only when its owner_id matches
## the showing owner, so a stale hide from a source the cursor already left
## doesn't kill a still-pending show from a different source.
signal tooltip_show_for_owner(entries: Array[TooltipData], anchor_rect: Rect2, owner_id: int)
signal tooltip_hide_for_owner(owner_id: int)
## Show the big InventoryCard preview for a weapon or equipment on hover. Pass
## anchor_rect to position next to the source (right-of-source, flips left).
## Exactly one of `weapon` or `equipment` should be set; the other is null.
signal inventory_preview_show_requested(weapon: Weapon, equipment: Equipment, anchor_rect: Rect2)
signal inventory_preview_hide_requested
signal selecting_cards_from_hand(limit: int)
signal finished_selecting_cards_from_hand(selected_cards: Array[CardUI])
signal lock_hand()
signal unlock_hand()
## Request a flip-reveal of the top card of `source_owner`'s draw pile (player
## or enemy). Listeners (BattleUI router) animate the reveal and emit
## `top_card_reveal_finished` when done. Card scripts await the finished signal
## to gate downstream effects (e.g. ravenous_rabble's pitch read).
signal top_card_reveal_requested(card: Card, source_owner: Node)
signal top_card_reveal_finished
## Request a fly-in animation for a card being added to a target combatant's
## pile. Listener (BattleUI) handles visuals; CardAddEffect emits this BEFORE
## mutating the resource pile so the listener can do the visual handoff
## (parent the CardUI into the target panel) ahead of the size_changed handler.
## Listeners must bracket their tween with register_card_add_animation_start /
## register_card_add_animation_end so Card.play can drain pending visuals
## before emitting card_play_finished — otherwise the enemy turn loop advances
## while the card is still flying.
signal card_add_animation_requested(card: Card, target: Node, destination: int)
## Emitted once per CardAddEffect fly-in completion (paired with the start
## bracket). Card.play awaits this in a loop to drain pending_card_add_animations.
signal card_add_animation_finished
var pending_card_add_animations: int = 0

func register_card_add_animation_start() -> void:
	pending_card_add_animations += 1

func register_card_add_animation_end() -> void:
	pending_card_add_animations -= 1
	card_add_animation_finished.emit()

func await_pending_card_add_animations() -> void:
	while pending_card_add_animations > 0:
		await card_add_animation_finished

#Player-related events
signal player_initial_hand_drawn
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_end_phase_started
signal player_hit
signal player_died
signal player_card_drawn(card: Card)
signal player_action_phase_started
signal player_blocks_declared
signal player_set_up #emitted once the player is initialized in the battle
signal player_attack_declared
signal player_attack_completed
## Fires the first time a card is played in a given player turn (after that
## card resolves). Used by Tabi Boots, Caffeine Tab, etc.
signal player_first_card_played(card: Card)
## Fires the first time an attack card is played in a given player turn.
## Used by Crow's Feather.
signal player_first_attack_played(card: Card)
## Fires after EVERY player card resolves (post-effects). Used by reactive
## "next non-attack" buffs (e.g. Mana-Threaded Greaves) that need to inspect
## the played card's type.
signal player_card_played(card: Card)
## Request that a specific Equipment instance destroy itself this frame. The
## EquipmentHandler that owns the instance handles teardown (on_destroyed
## hook, removal from inventory, etc.) via _destroy_equipment. Used by
## active-ability equipment that consumes itself (Spellbinder's Robe).
signal equipment_self_destruct_requested(equipment: Equipment)

#Enemy-related events
signal enemy_phase_ended #Called when all enemies are done, move to player turn
signal enemy_died(enemy: Enemy)
## Fires when EnemyHandler.spawn_enemy completes setup for a mid-battle spawn
## (Slime split today; any future spawn mechanic too). Aura-style statuses
## subscribe to extend their effect onto newly-arrived allies — initial
## battle-start enemies don't fire this; the regular per-enemy setup pass
## handles them.
signal enemy_spawned(enemy: Enemy)
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
signal battle_stalemated
signal status_tooltip_requested(statuses: Array[Status])
## Emitted by BattleUI after the centered TURN announcement tween completes
## (fully faded out). ENEMY_SOT waits on this before kicking off its SOT
## cascade so the player can read who is about to act. Fires for both
## PLAYER_SOT and ENEMY_SOT announcements — player side ignores it.
signal turn_announcement_finished

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

## Emitted by relics that grant the player gold (e.g. Echoing Coin). Run.gd
## listens and bumps RunStats.gold — relics don't hold a direct RunStats ref.
signal relic_gold_granted(amount: int)

#Random Event room-related events
signal event_room_exited
