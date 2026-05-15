class_name BattleReward
extends Control

const CARD_REWARDS = preload("res://scenes/ui/card_rewards.tscn")
const REWARD_BUTTON = preload("res://scenes/ui/reward_button.tscn")
const GOLD_ICON := preload("res://art/gold.png")
const GOLD_TEXT := "%s gold"
const CARD_ICON := preload("res://art/rarity.png")
const CARD_TEXT := "Pick Card or Item"
const ITEM_ROLL_RETRIES := 5

@export var run_stats: RunStats
@export var character_stats: CharacterStats
@export var relic_handler: RelicHandler
@export var draftable_inventory: DraftableInventory


@onready var rewards: VBoxContainer = %Rewards

var card_reward_total_weight := 0.0
var card_rarity_weights := {
	Card.Rarity.COMMON: 0.0,
	Card.Rarity.UNCOMMON: 0.0,
	Card.Rarity.RARE: 0.0
}

func _ready() -> void:
	for node: Node in rewards.get_children():
		node.queue_free()

func add_gold_reward(amount: int) -> void:
	var gold_reward := REWARD_BUTTON.instantiate() as RewardButton
	gold_reward.reward_icon = GOLD_ICON
	gold_reward.reward_text = GOLD_TEXT % amount
	gold_reward.pressed.connect(_on_gold_reward_taken.bind(amount))
	rewards.add_child.call_deferred(gold_reward)

func add_card_reward() -> void:
	var card_reward := REWARD_BUTTON.instantiate() as RewardButton
	card_reward.reward_icon = CARD_ICON
	card_reward.reward_text = CARD_TEXT
	card_reward.pressed.connect(_show_draft_rewards)
	rewards.add_child.call_deferred(card_reward)

func add_relic_reward(relic: Relic) -> void:
	if not relic:
		return

	var relic_reward := REWARD_BUTTON.instantiate() as RewardButton
	relic_reward.reward_icon = relic.icon
	relic_reward.reward_text = relic.relic_name
	relic_reward.pressed.connect(_on_relic_reward_taken.bind(relic))
	rewards.add_child.call_deferred(relic_reward)

func add_equipment_reward(equipment: Equipment) -> void:
	if not equipment:
		return

	var eq_reward := REWARD_BUTTON.instantiate() as RewardButton
	eq_reward.reward_icon = equipment.icon
	eq_reward.reward_text = equipment.equipment_name
	eq_reward.pressed.connect(_on_equipment_reward_taken.bind(equipment))
	rewards.add_child.call_deferred(eq_reward)


func add_weapon_reward(weapon: Weapon) -> void:
	if not weapon:
		return

	var wp_reward := REWARD_BUTTON.instantiate() as RewardButton
	wp_reward.reward_icon = weapon.icon
	wp_reward.reward_text = weapon.weapon_name
	wp_reward.pressed.connect(_on_weapon_reward_taken.bind(weapon))
	rewards.add_child.call_deferred(wp_reward)


## Public alias for the inventory roller — used by elite reward path which
## guarantees a weapon-or-equipment drop alongside the standard cards/gold.
func roll_inventory_item() -> Resource:
	return _roll_inventory_item()

func _show_draft_rewards() -> void:
	if not run_stats or not character_stats:
		return

	var card_rewards := CARD_REWARDS.instantiate() as CardRewards
	add_child(card_rewards)
	card_rewards.reward_selected.connect(_on_reward_taken)

	var reward_array: Array[Resource] = []
	var available_cards: Array[Card] = character_stats.draftable_cards.duplicate_cards()

	for i in run_stats.card_rewards:
		var picked_card := _roll_one_card(available_cards)
		if picked_card:
			reward_array.append(picked_card)
			available_cards.erase(picked_card)

	var item := _roll_inventory_item()
	if item:
		reward_array.append(item)
	else:
		var fallback_card := _roll_one_card(available_cards)
		if fallback_card:
			reward_array.append(fallback_card)
			available_cards.erase(fallback_card)

	card_rewards.rewards = reward_array
	card_rewards.show()

func _roll_one_card(available_cards: Array[Card]) -> Card:
	_setup_card_chances()
	var roll := RNG.instance.randf_range(0.0, card_reward_total_weight)
	for rarity: Card.Rarity in card_rarity_weights:
		if card_rarity_weights[rarity] > roll:
			_modify_weights(rarity)
			return _get_random_available_card(available_cards, rarity)
	return null

func _roll_inventory_item() -> Resource:
	if not draftable_inventory or not character_stats:
		return null

	for attempt in ITEM_ROLL_RETRIES:
		var roll_weapon := RNG.instance.randf() < 0.25
		var pool: Array = []
		if roll_weapon:
			pool = draftable_inventory.weapons.duplicate()
			pool.append_array(character_stats.draftable_weapons)
		else:
			pool = draftable_inventory.equipment.duplicate()
			pool.append_array(character_stats.draftable_equipment)

		var rarity := _roll_item_rarity()

		var filtered := pool.filter(
			func(item):
				if not item:
					return false
				if not item.can_appear_as_reward(character_stats):
					return false
				if item.rarity != rarity:
					return false
				if item.allow_duplicate_in_draft:
					return true
				if roll_weapon:
					return not character_stats.inventory.has_weapon(item.id)
				else:
					return not character_stats.inventory.has_equipment(item.id)
		)
		if not filtered.is_empty():
			return RNG.array_pick_random(filtered)

	return null

func _roll_item_rarity() -> Card.Rarity:
	_setup_card_chances()
	var roll := RNG.instance.randf_range(0.0, card_reward_total_weight)
	for rarity: Card.Rarity in card_rarity_weights:
		if card_rarity_weights[rarity] > roll:
			return rarity
	return Card.Rarity.COMMON

func _setup_card_chances() -> void:
	card_reward_total_weight = run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight
	card_rarity_weights[Card.Rarity.COMMON] = run_stats.common_weight
	card_rarity_weights[Card.Rarity.UNCOMMON] = run_stats.common_weight + run_stats.uncommon_weight
	card_rarity_weights[Card.Rarity.RARE] = card_reward_total_weight

func _modify_weights(rarity_rolled: Card.Rarity) -> void:
	if rarity_rolled == Card.Rarity.RARE:
		run_stats.rare_weight = RunStats.BASE_RARE_WEIGHT
	else:
		run_stats.rare_weight = clampf(run_stats.rare_weight + 0.3, run_stats.BASE_RARE_WEIGHT, 5.0)

func _get_random_available_card(available_cards: Array[Card], with_rarity: Card.Rarity) -> Card:
	var all_possible_cards := available_cards.filter(
		func(card: Card):
			return card.rarity == with_rarity
	)
	return RNG.array_pick_random(all_possible_cards)

func _on_gold_reward_taken(amount: int) -> void:
	if not run_stats:
		return

	run_stats.gold += amount

func _on_reward_taken(reward: Resource) -> void:
	if not reward or not character_stats:
		return

	if reward is Card:
		character_stats.deck.add_card(reward)
	elif reward is Weapon:
		character_stats.add_weapon(reward)
	elif reward is Equipment:
		character_stats.add_equipment(reward)

func _on_relic_reward_taken(relic: Relic) -> void:
	if not relic or not relic_handler:
		return

	relic_handler.add_relic(relic)

func _on_equipment_reward_taken(equipment: Equipment) -> void:
	if not equipment or not character_stats:
		return

	character_stats.add_equipment(equipment)


func _on_weapon_reward_taken(weapon: Weapon) -> void:
	if not weapon or not character_stats:
		return

	character_stats.add_weapon(weapon)

func _on_back_button_pressed() -> void:
	Events.battle_reward_exited.emit()
