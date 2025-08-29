#Enemy turn
#1. start turn (make array of enemies)
#2. iterate through those enemies
#	3. start of turn statuses
#	4. enemy_ai start_start turn builds turn plan
#	5. enemy_ai performs action until returns 0 (when out of actions)
#		5.1. This is where player can block
#		5.2. Apply effects of attack after blocks
#	6. emit action_complete (should probably be changed to enemy turn complete)
#	7. End of turn statuses
#	Repeat for next enemy

class_name EnemyHandler
extends Node2D

var acting_enemies: Array[Enemy] = []

func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.enemy_turn_completed.connect(_on_enemy_turn_completed)
	#Events.enemy_action_completed.connect(_on_enemy_action_completed)
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
		new_enemy_child.stats.draw_pile = new_enemy_child.stats.starting_deck.custom_duplicate()
		new_enemy_child.stats.draw_pile.shuffle()
		new_enemy_child.stats.discard = CardPile.new()
		new_enemy_child.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(new_enemy_child))
		new_enemy_child.setup_ai()
		new_enemy_child.enemy_ai.plan_created.connect(_on_plan_created)
		new_enemy_child.enemy_action_completed.connect(_on_enemy_action_completed)
	
	all_new_enemies.queue_free()

func reset_enemy_actions() -> void:
	for enemy: Enemy in get_children():
		enemy.current_action = null
		enemy.update_intent()

func start_turn() -> void:
	if get_child_count() == 0:
		return
	
	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)
	
	_start_next_enemy_turn()

func _start_next_enemy_turn() -> void:
	if acting_enemies.is_empty():
		enemy_end_phase()
		return
	
	acting_enemies[0].status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)

func _on_enemy_statuses_applied(type: Status.Type, enemy: Enemy) -> void:
	match type:
		Status.Type.START_OF_TURN:
			enemy.enemy_ai.start_turn(get_tree().get_first_node_in_group("player").stats.health)
		Status.Type.END_OF_TURN:
			acting_enemies.erase(enemy)
			_start_next_enemy_turn()

func _on_enemy_died(enemy: Enemy) -> void:
	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)
	
	if is_enemy_turn:
		_start_next_enemy_turn()

func _on_enemy_turn_completed(enemy: Enemy) -> void:
	enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)

func _on_player_action_phase_started() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()

func _on_plan_created(enemy: Enemy) -> void:
	enemy.declare_next_attack()
	#Events.enemy_attack_declared.emit()

func _on_enemy_action_completed(enemy: Enemy) ->void:
	enemy.declare_next_attack()
	#Events.enemy_attack_declared.emit()

func enemy_end_phase() -> void:
	for enemy: Enemy in get_children():
		enemy.cleanup_phase()
	
	Events.enemy_phase_ended.emit()
