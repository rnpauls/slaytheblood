class_name Battle
extends Node2D

@export var battle_stats: BattleStats
@export var char_stats: CharacterStats
@export var music: AudioStream
@export var relics: RelicHandler

@onready var battle_ui: BattleUI = $BattleUI as BattleUI
@onready var player_handler: PlayerHandler = $PlayerHandler as PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler as EnemyHandler
@onready var player: Player = $Player as Player

func _ready() -> void:
	
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_phase_ended.connect(_on_enemy_phase_ended)
	
	Events.player_end_phase_started.connect(player_handler.end_turn)
	Events.player_turn_ended.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
#mess with a card in hand
#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_accept"):
		#var card_ui = player_handler.hand.get_child(0) as CardUI
		#card_ui.card.cost -=  1
		#card_ui.card = card_ui.card

func start_battle() ->void:
	get_tree().paused = false
	MusicPlayer.play(music, true)
	
	battle_ui.char_stats = char_stats
	player.stats = char_stats
	player_handler.relics = relics
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()
	
	relics.relics_activated.connect(_on_relics_activated)
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)
	print_debug("TODO: Implement random start turn?")
	if not player_handler.player:
		await Events.player_set_up
	player_handler.draw_cards(player.stats.cards_per_turn, true)

func _on_enemy_phase_ended() ->void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()

func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics):
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT)

func _on_player_died() -> void:
	Events.battle_over_screen_requested.emit("Game Over!", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()

func _on_relics_activated(type: Relic.Type) -> void:
	match type:
		Relic.Type.START_OF_COMBAT:
			player_handler.start_battle(char_stats)
			battle_ui.initialize_card_pile_ui()
		Relic.Type.END_OF_COMBAT:
			Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)
