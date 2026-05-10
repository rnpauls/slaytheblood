class_name BattleStatsPool
extends Resource

@export var pool: Array[BattleStats]
## Elite encounters live here, separate from the tiered pool. Elite rooms
## (Room.Type.ELITE_MONSTER) draw from this list uniformly.
@export var elite_pool: Array[BattleStats]

# Tier int -> total accumulated weight. Sized dynamically from `pool` in
# setup() so any tier values present in the pool are usable.
var total_weights_by_tier: Dictionary = {}


func _get_all_battles_for_tier(tier: int) -> Array[BattleStats]:
	return pool.filter(
		func(battle: BattleStats):
			return battle.battle_tier == tier
	)


func _setup_weight_for_tier(tier: int) -> void:
	var battles := _get_all_battles_for_tier(tier)
	var total := 0.0

	for battle: BattleStats in battles:
		total += battle.weight
		battle.accumulated_weight = total

	total_weights_by_tier[tier] = total


func get_random_battle_for_tier(tier: int) -> BattleStats:
	if not total_weights_by_tier.has(tier):
		return null
	var roll := randf_range(0.0, total_weights_by_tier[tier])
	var battles := _get_all_battles_for_tier(tier)

	for battle: BattleStats in battles:
		if battle.accumulated_weight > roll:
			return battle

	return null


## Pick a random elite encounter. Uniform across elite_pool — no tier weighting.
func get_random_elite_battle() -> BattleStats:
	if elite_pool.is_empty():
		return null
	return elite_pool[randi() % elite_pool.size()]


func setup() -> void:
	total_weights_by_tier.clear()
	var tiers := {}
	for battle: BattleStats in pool:
		tiers[battle.battle_tier] = true
	for tier: int in tiers:
		_setup_weight_for_tier(tier)
