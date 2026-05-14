# Owns acting_enemies and per-enemy setup/cleanup. Iteration through the
# enemy phase is driven by TurnStateMachine — the per-enemy SOT/ACTING/EOT
# states under scenes/battle/turn_states/ subscribe directly to each
# enemy's status_handler / enemy_ai signals.

class_name EnemyHandler
extends Node2D

const HEALTH_VARIATION := 2

var acting_enemies: Array[Enemy] = []

## Set by Battle.start_battle so each enemy's AI gets the player ref by
## injection instead of a get_first_node_in_group lookup at setup time.
var player_target: Player

## Set by Battle.start_battle so each enemy gets the BattleUI ref by
## injection. Propagated to enemy.battle_ui in setup_enemies.
var battle_ui_ref: BattleUI

func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.player_action_phase_started.connect(_on_player_action_phase_started)

func setup_enemies(battle_stats: BattleStats) -> void:
	if not battle_stats:
		return

	for enemy: Enemy in get_children():
		enemy.queue_free()

	var all_new_enemies := battle_stats.enemies.instantiate()

	for new_enemy: Node2D in all_new_enemies.get_children():
		var new_enemy_child := new_enemy.duplicate() as Enemy
		add_child(new_enemy_child)
		new_enemy_child.battle_ui = battle_ui_ref

		# One-shot spawn HP jitter. Lives here (not in Enemy._init_stats) because
		# the stats setter fires on both .instantiate() and .duplicate(), which
		# would compound the roll. This loop runs exactly once per enemy.
		var hp_delta := RNG.instance.randi_range(-HEALTH_VARIATION, HEALTH_VARIATION)
		new_enemy_child.stats.max_health = maxi(1, new_enemy_child.stats.max_health + hp_delta)

		new_enemy_child.stats.draw_pile = new_enemy_child.stats.starting_deck.custom_duplicate()
		new_enemy_child.stats.draw_pile.shuffle()
		new_enemy_child.stats.discard = CardPile.new()
		new_enemy_child.stats.exhaust = CardPile.new()
		new_enemy_child.draw_cards(new_enemy_child.stats.cards_per_turn)
		new_enemy_child.setup_ai(player_target)

	all_new_enemies.queue_free()

func reset_enemy_actions() -> void:
	for enemy: Enemy in get_children():
		enemy.current_action = null

# Populates acting_enemies for the SM to iterate over. Called from
# EnemyStartOfTurnState.enter() on first entry of the enemy phase.
func start_turn() -> void:
	if get_child_count() == 0:
		return

	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)

func _on_enemy_died(enemy: Enemy) -> void:
	acting_enemies.erase(enemy)

func _on_player_action_phase_started() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()

func enemy_end_phase() -> void:
	for enemy: Enemy in get_children():
		enemy.cleanup_phase()

	Events.enemy_phase_ended.emit()
