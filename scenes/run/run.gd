class_name Run
extends Node

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const BATTLE_REWARD_SCENE := preload("res://scenes/battle_reward/battle_reward.tscn")
const CAMPFIRE_SCENE := preload("res://scenes/campfire/campfire.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop.tscn")
const TREASURE_SCENE := preload("res://scenes/treasure/treasure.tscn")
const WIN_SCREEN_SCENE = preload("res://scenes/win_screen/win_screen.tscn")
const DRAFTABLE_INVENTORY := preload("res://custom_resources/draftable_inventory.tres")
const MAIN_MENU_PATH = "res://scenes/ui/main_menu.tscn"
const NON_COMBAT_MUSIC := preload("res://art/music/deuslower-medieval-ambient-236809.mp3")

@export var run_startup: RunStartup

@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var health_ui: HealthUI = %HealthUI
@onready var gold_ui: GoldUI = %GoldUI
@onready var relic_handler: RelicHandler = %RelicHandler
@onready var inventory_button: TextureButton = %InventoryButton
@onready var inventory_view: InventoryView = %InventoryView
@onready var deck_button: CardPileOpener = %DeckButton
@onready var deck_view: CardPileView = %DeckView
@onready var pause_menu: PauseMenu = $PauseMenu

@onready var battle_button: Button = %BattleButton
@onready var map_button: TextureButton = %MapButton
@onready var debug_map_button: Button = %DebugMapButton
@onready var shop_button: Button = %ShopButton
@onready var treasure_button: Button = %TreasureButton
@onready var rewards_button: Button = %RewardsButton
@onready var campfire_button: Button = %CampfireButton

var stats: RunStats
var character: CharacterStats
var save_data: SaveGame
var peeked_view: Node = null

func _ready() -> void:
	if not run_startup:
		return
	
	pause_menu.save_and_quit.connect(
		func():
			get_tree().change_scene_to_file(MAIN_MENU_PATH)
	)
	MusicPlayer.play(NON_COMBAT_MUSIC, true)
	match run_startup.type:
		RunStartup.Type.NEW_RUN:
			character = run_startup.picked_character.create_instance()
			_start_run()
		RunStartup.Type.CONTINUED_RUN:
			_load_run()

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("cheat"):
		#get_tree().call_group("enemies", "queue_free")

func _start_run() -> void:
	stats = RunStats.new()
	
	_setup_event_connections()
	_setup_top_bar()
	
	map.generate_new_map()
	map.unlock_floor(0)
	
	save_data = SaveGame.new()
	_save_run(true)

func _save_run(was_on_map: bool) -> void:
	save_data.rng_seed = RNG.instance.seed
	save_data.rng_state = RNG.instance.state
	save_data.run_stats = stats
	save_data.char_stats = character
	save_data.current_deck = character.deck
	save_data.current_health = character.health
	save_data.relics = relic_handler.get_all_relics()
	save_data.last_room = map.last_room
	save_data.map_data = map.map_data.duplicate()
	save_data.floors_climbed = map.floors_climbed
	save_data.was_on_map = was_on_map
	save_data.current_inventory = character.inventory
	save_data.current_hand_left = character.hand_left
	save_data.current_hand_right = character.hand_right
	save_data.current_equipment_head = character.equipment_head
	save_data.current_equipment_chest = character.equipment_chest
	save_data.current_equipment_arms = character.equipment_arms
	save_data.current_equipment_legs = character.equipment_legs
	save_data.save_data()

func _load_run() -> void:
	save_data = SaveGame.load_data()
	assert(save_data, "Couldn't load last save")
	
	RNG.set_from_save_data(save_data.rng_seed, save_data.rng_state)
	stats = save_data.run_stats
	character = save_data.char_stats
	character.deck = save_data.current_deck
	character.inventory = save_data.current_inventory
	character.hand_left = save_data.current_hand_left
	character.hand_right = save_data.current_hand_right
	character.equipment_head = save_data.current_equipment_head
	character.equipment_chest = save_data.current_equipment_chest
	character.equipment_arms = save_data.current_equipment_arms
	character.equipment_legs = save_data.current_equipment_legs
	character.health = save_data.current_health
	relic_handler.add_relics(save_data.relics)
	_setup_top_bar()
	_setup_event_connections()
	
	map.load_map(save_data.map_data, save_data.floors_climbed, save_data.last_room)
	if save_data.last_room and not save_data.was_on_map:
		_on_map_exited(save_data.last_room)
	elif save_data.last_room:
		map.unlock_next_rooms()

func _change_view(scene: PackedScene) -> Node:
	# Outgoing view is queue_freed below — its tooltip-emitting children won't
	# get a paired mouse_exited, so clear any open tooltip up front.
	Events.tooltip_hide_requested.emit()
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	get_tree().paused = false
	var new_view := scene.instantiate()
	current_view.add_child(new_view)
	map.hide_map()

	# Lock equip/unequip in the inventory view for the duration of combat.
	inventory_view.combat_locked = scene == BATTLE_SCENE

	return new_view

func _show_map() -> void:
	Events.tooltip_hide_requested.emit()
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	map.show_map()
	map.hide_current_marker()
	map.unlock_next_rooms()
	inventory_view.combat_locked = false

	_save_run(true)

func _debug_show_map() -> void:
	_show_map()
	map.unlock_all_rooms()

func _peek_map() -> void:
	if peeked_view:
		current_view.add_child(peeked_view)
		peeked_view = null
		map.hide_current_marker()
		map.hide_map()
		return

	if current_view.get_child_count() == 0:
		return

	Events.tooltip_hide_requested.emit()
	peeked_view = current_view.get_child(0)
	current_view.remove_child(peeked_view)
	map.show_map()
	if map.last_room:
		map.show_current_marker(map.last_room)

func _setup_event_connections() -> void:
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_show_map)
	Events.campfire_exited.connect(_show_map)
	Events.map_exited.connect(_on_map_exited)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_on_treasure_room_exited)
	Events.event_room_exited.connect(_show_map)
	
	battle_button.pressed.connect(_change_view.bind(BATTLE_SCENE))
	campfire_button.pressed.connect(_change_view.bind(CAMPFIRE_SCENE))
	map_button.pressed.connect(_peek_map)
	debug_map_button.pressed.connect(_debug_show_map)
	rewards_button.pressed.connect(_change_view.bind(BATTLE_REWARD_SCENE))
	shop_button.pressed.connect(_change_view.bind(SHOP_SCENE))
	treasure_button.pressed.connect(_change_view.bind(TREASURE_SCENE))

func _setup_top_bar() -> void:
	character.stats_changed.connect(health_ui.update_stats.bind(character))
	health_ui.update_stats(character)
	gold_ui.run_stats = stats
	relic_handler.add_relic(character.starting_relic)
	deck_button.card_pile = character.deck
	deck_view.card_pile = character.deck
	deck_button.pressed.connect(deck_view.show_current_view.bind("Deck"))
	inventory_button.pressed.connect(inventory_view.show_current_view)
	inventory_view.inventory = character.inventory
	inventory_view.character = character

func _show_regular_battle_rewards() -> void:
	var reward_scene := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character
	reward_scene.draftable_inventory = DRAFTABLE_INVENTORY

	reward_scene.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())
	reward_scene.add_card_reward()
	reward_scene.add_card_reward()

func _on_battle_room_entered(room: Room) -> void:
	var battle_scene: Battle = _change_view(BATTLE_SCENE) as Battle
	battle_scene.char_stats = character
	battle_scene.battle_stats = room.battle_stats
	battle_scene.relics = relic_handler
	battle_scene.start_battle()

func _on_treasure_room_entered() -> void:
	var treasure_scene := _change_view(TREASURE_SCENE)  as Treasure
	treasure_scene.relic_handler = relic_handler
	treasure_scene.char_stats = character
	treasure_scene.generate_relic()

func _on_treasure_room_exited(relic: Relic) -> void:
	var reward_scene := _change_view(BATTLE_REWARD_SCENE)  as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character
	reward_scene.relic_handler = relic_handler
	
	reward_scene.add_relic_reward(relic)

func _on_campfire_entered() -> void:
	var campfire:= _change_view(CAMPFIRE_SCENE) as Campfire
	campfire.char_stats = character

func _on_shop_entered() -> void:
	var shop := _change_view(SHOP_SCENE) as Shop
	shop.char_stats = character
	shop.run_stats = stats
	shop.relic_handler = relic_handler
	Events.shop_entered.emit(shop)
	shop.populate_shop()

func _on_event_room_entered(room: Room) -> void:
	var event_room := _change_view(room.event_scene) as EventRoom
	event_room.character_stats = character
	event_room.run_stats = stats
	event_room.setup()

func _on_battle_won() -> void:
	MusicPlayer.play(NON_COMBAT_MUSIC, true)
	if map.floors_climbed == MapGenerator.FLOORS:
		var win_screen := _change_view(WIN_SCREEN_SCENE) as WinScreen
		win_screen.character = character
		SaveGame.delete_data()
	else:
		_show_regular_battle_rewards()

func _on_map_exited(room: Room) -> void:
	_save_run(false)
	
	match room.type:
		Room.Type.MONSTER:
			_on_battle_room_entered(room)
		Room.Type.TREASURE:
			_on_treasure_room_entered()
		Room.Type.CAMPFIRE:
			_on_campfire_entered()
		Room.Type.SHOP:
			_on_shop_entered()
		Room.Type.BOSS:
			_on_battle_room_entered(room)
		Room.Type.EVENT:
			_on_event_room_entered(room)
