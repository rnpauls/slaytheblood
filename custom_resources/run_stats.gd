class_name RunStats
extends Resource

signal gold_changed
signal card_removal_cost_changed

const STARTING_GOLD := 100
const BASE_CARD_REWARDS := 3
const BASE_COMMON_WEIGHT := 6.0
const BASE_UNCOMMON_WEIGHT := 3.7
const BASE_RARE_WEIGHT := 0.3
const STARTING_CARD_REMOVAL_COST := 75
const CARD_REMOVAL_COST_INCREMENT := 25

@export var gold := STARTING_GOLD : set = set_gold
@export var card_rewards := BASE_CARD_REWARDS
@export_range(0.0, 10.0) var common_weight := BASE_COMMON_WEIGHT
@export_range(0.0, 10.0) var uncommon_weight := BASE_UNCOMMON_WEIGHT
@export_range(0.0, 10.0) var rare_weight := BASE_RARE_WEIGHT
@export var card_removal_cost := STARTING_CARD_REMOVAL_COST : set = set_card_removal_cost

func set_gold(new_amount : int) -> void:
	gold = new_amount
	gold_changed.emit()


func set_card_removal_cost(new_cost: int) -> void:
	card_removal_cost = new_cost
	card_removal_cost_changed.emit()


func reset_weights() -> void:
	common_weight = BASE_COMMON_WEIGHT
	uncommon_weight = BASE_UNCOMMON_WEIGHT
	rare_weight = BASE_RARE_WEIGHT
