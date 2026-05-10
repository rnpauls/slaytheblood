class_name Battle
extends Node2D

@export var battle_stats: BattleStats
@export var char_stats: CharacterStats
@export var music: AudioStream
@export var relics: RelicHandler
@onready var hand_left_weapon: WeaponHandler = %LeftWeaponHandler
@onready var hand_right_weapon: WeaponHandler = %RightWeaponHandler
@onready var hand_left_equipment: EquipmentHandler = get_node_or_null("%LeftOffhandEquipmentHandler")
@onready var hand_right_equipment: EquipmentHandler = get_node_or_null("%RightOffhandEquipmentHandler")
@onready var equipment_head: EquipmentHandler = get_node_or_null("%HeadEquipmentHandler")
@onready var equipment_chest: EquipmentHandler = get_node_or_null("%ChestEquipmentHandler")
@onready var equipment_arms: EquipmentHandler = get_node_or_null("%ArmsEquipmentHandler")
@onready var equipment_legs: EquipmentHandler = get_node_or_null("%LegsEquipmentHandler")

@onready var battle_ui: BattleUI = $BattleUI as BattleUI
@onready var player_handler: PlayerHandler = $PlayerHandler as PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler as EnemyHandler
@onready var player: Player = $Player as Player

# Set up in start_battle() once handler refs are wired. Owns outer
# turn-phase transitions (player turn / enemy turn / victory / defeat).
# See scenes/battle/turn_state_machine.gd for the design.
var turn_state_machine: TurnStateMachine

func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.player_died.connect(_on_player_died)

func start_battle() ->void:
	get_tree().paused = false
	MusicPlayer.play(music, true)

	battle_ui.char_stats = char_stats
	player.stats = char_stats
	player_handler.relics = relics
	player_handler.hand_left_weapon = hand_left_weapon
	player_handler.hand_right_weapon = hand_right_weapon
	player_handler.hand_left_equipment = hand_left_equipment
	player_handler.hand_right_equipment = hand_right_equipment
	player_handler.equipment_head = equipment_head
	player_handler.equipment_chest = equipment_chest
	player_handler.equipment_arms = equipment_arms
	player_handler.equipment_legs = equipment_legs

	hand_left_weapon.owner_of_weapon = player
	hand_right_weapon.owner_of_weapon = player
	for eq_handler in [hand_left_equipment, hand_right_equipment, equipment_head, equipment_chest, equipment_arms, equipment_legs]:
		if eq_handler:
			eq_handler.owner_of_equipment = player

	# Inject the player ref so each enemy's AI gets target via setup, not
	# via a group lookup at setup time.
	enemy_handler.player_target = player
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()

	# Spin up the turn state machine BEFORE the relic cascade kicks off,
	# so COMBAT_START is active and listening when player_initial_hand_drawn
	# eventually fires at the end of the setup chain.
	_setup_turn_state_machine()

	# Initialize the player (equipment, deck, refs) BEFORE relics flash so
	# equipment is visible during the SOC animation and draw_card doesn't
	# race against the relic tween waiting on Events.player_set_up.
	player_handler.start_battle(char_stats)
	battle_ui.initialize_card_pile_ui()

	relics.relics_activated.connect(_on_relics_activated)
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)

# Builds the SM as a child node and registers all 9 phase states.
# Done programmatically rather than in battle.tscn to keep the scene
# file untouched in pass 1 — the SM and its states can be moved into
# the scene tree later if scene-based editing becomes useful.
func _setup_turn_state_machine() -> void:
	turn_state_machine = TurnStateMachine.new()
	turn_state_machine.name = "TurnStateMachine"
	add_child(turn_state_machine)

	_add_turn_state(CombatStartState.new(), TurnState.State.COMBAT_START)
	_add_turn_state(PlayerStartOfTurnState.new(), TurnState.State.PLAYER_SOT)
	_add_turn_state(PlayerActionState.new(), TurnState.State.PLAYER_ACTION)
	_add_turn_state(PlayerEndOfTurnState.new(), TurnState.State.PLAYER_EOT)
	_add_turn_state(EnemyStartOfTurnState.new(), TurnState.State.ENEMY_SOT)
	_add_turn_state(EnemyActingState.new(), TurnState.State.ENEMY_ACTING)
	_add_turn_state(EnemyEndOfTurnState.new(), TurnState.State.ENEMY_EOT)
	_add_turn_state(VictoryState.new(), TurnState.State.VICTORY)
	_add_turn_state(DefeatState.new(), TurnState.State.DEFEAT)
	_add_turn_state(StalemateState.new(), TurnState.State.STALEMATE)

	turn_state_machine.init(self)

func _add_turn_state(state_node: TurnState, key: TurnState.State) -> void:
	state_node.state = key
	state_node.name = TurnState.State.keys()[key]
	turn_state_machine.add_child(state_node)

func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics):
		# Mark the SM terminal first so any in-flight transitions (e.g. an
		# enemy_phase_ended fired the same frame the last enemy died)
		# become no-ops once we leave the current state.
		if turn_state_machine:
			turn_state_machine.force_transition(TurnState.State.VICTORY)
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT)

func _on_player_died() -> void:
	if turn_state_machine:
		turn_state_machine.force_transition(TurnState.State.DEFEAT)
	Events.battle_over_screen_requested.emit("Game Over!", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()

func _on_relics_activated(type: Relic.Type) -> void:
	match type:
		Relic.Type.START_OF_COMBAT:
			player_handler.start_turn()
			player_handler.draw_cards(player.stats.cards_per_turn, 'init')
		Relic.Type.END_OF_COMBAT:
			Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)
