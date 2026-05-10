class_name MapGenerator
extends Node

const X_DIST := 140
const Y_DIST := 160
const PLACEMENT_RANDOMNESS := 25
const FLOORS := 15
const MAP_WIDTH := 7
const PATHS := 6
const MONSTER_ROOM_WEIGHT := 12.0
const ELITE_ROOM_WEIGHT := 3.0
const EVENT_ROOM_WEIGHT := 5.0
const SHOP_ROOM_WEIGHT := 2.5
const CAMPFIRE_ROOM_WEIGHT := 4.0

const ELITE_MIN_ROW := 4

@export var battle_stats_pool: BattleStatsPool
@export var event_room_pool: EventRoomPool

# Set by Map.generate_new_map() before generate_map() is called. Drives which
# tier of BattleStats the map pulls from (see _tier_for).
var act: int = 1

var random_room_type_weights = {
	Room.Type.MONSTER: 0.0,
	Room.Type.ELITE_MONSTER: 0.0,
	Room.Type.CAMPFIRE: 0.0,
	Room.Type.SHOP: 0.0,
	Room.Type.EVENT: 0.0
}

var random_room_type_total_weight := 0
var map_data: Array[Array]

	
func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()
	
	for j in starting_points:
		var current_j := j
		for i in FLOORS -1:
			current_j = _setup_conection(i, current_j)
	
	battle_stats_pool.setup()
	
	_setup_boss_room()
	_setup_random_room_weights()
	_setup_room_types()
	
	return map_data

func _generate_initial_grid() -> Array[Array]:
	var result: Array[Array] = []
	
	for i in FLOORS:
		var adjacent_rooms: Array[Room] = []
		
		for j in MAP_WIDTH:
			var current_room := Room.new()
			var offset := Vector2(randf(), randf()) * PLACEMENT_RANDOMNESS
			current_room.position = Vector2(j * X_DIST, i * -1 *Y_DIST) + offset
			current_room.row = i
			current_room.column = j
			current_room.next_rooms = []
			
			#Boss room has non-random Y
			if i == FLOORS -1:
				current_room.position.y = (i+1) * -1 * Y_DIST
			
			adjacent_rooms.append(current_room)
		result.append(adjacent_rooms)
	return result

func _get_random_starting_points() -> Array[int]:
	var y_coordinates: Array[int]
	var unique_points: int = 0
	
	while unique_points <2:
		unique_points = 0
		y_coordinates = []
		
		for i in PATHS:
			var starting_point := randi_range(0, MAP_WIDTH -1)
			if not y_coordinates.has(starting_point):
				unique_points += 1
			
			y_coordinates.append(starting_point)
	
	return y_coordinates

func _setup_conection(i: int, j: int) -> int:
	var next_room: Room = null
	var current_room := map_data[i][j] as Room
	
	while not next_room or _would_cross_existing_path(i,j,next_room):
		#var random_j := clampi(randi_range(j-1, j+1), 0, MAP_WIDTH -1)
		var random_j := randi_range(max(j - 1, 0), min(j + 1, MAP_WIDTH - 1))
		next_room = map_data[i+1][random_j]
	
	current_room.next_rooms.append(next_room)
	
	return next_room.column

func _would_cross_existing_path(i : int, j : int, room : Room) -> bool:
	var left_neighbor: Room
	var right_neighbor: Room
	
	#if j==0 theres no left neighbor
	if j>0:
		left_neighbor = map_data[i][j-1]
	#if j == map_width -1 theres no right neighbor
	if j < MAP_WIDTH -1:
		right_neighbor = map_data[i][j+1]
	
	#Can only cross right if there is a right neighbor and we are going right
	if right_neighbor and room.column > j:
		for next_room: Room in right_neighbor.next_rooms:
			#cant cross in right dir if right neighbor goes left
			if next_room.column < room.column:
				return true
	
	if left_neighbor and room.column < j:
		for next_room: Room in left_neighbor.next_rooms:
			if next_room.column > room.column:
				return true
				
	return false

func _setup_boss_room() -> void:
	var middle := floori(MAP_WIDTH*0.5)
	var boss_room := map_data[FLOORS -1][middle] as Room
	
	for j in MAP_WIDTH:
		var current_room = map_data[FLOORS -2][j] as Room
		if current_room.next_rooms:
			current_room.next_rooms = [] as Array[Room]
			current_room.next_rooms.append(boss_room)
	
	boss_room.type = Room.Type.BOSS
	boss_room.battle_stats = battle_stats_pool.get_random_battle_for_tier(_tier_for("boss"))
			
func _setup_random_room_weights()-> void:
	# Cumulative thresholds for weighted random pick. Order: MONSTER, ELITE,
	# CAMPFIRE, SHOP, EVENT. Each entry is the running sum so a single uniform
	# roll in [0, total) selects via the first threshold it falls under.
	random_room_type_weights[Room.Type.MONSTER] = MONSTER_ROOM_WEIGHT
	random_room_type_weights[Room.Type.ELITE_MONSTER] = MONSTER_ROOM_WEIGHT + ELITE_ROOM_WEIGHT
	random_room_type_weights[Room.Type.CAMPFIRE] = MONSTER_ROOM_WEIGHT + ELITE_ROOM_WEIGHT + CAMPFIRE_ROOM_WEIGHT
	random_room_type_weights[Room.Type.SHOP] = MONSTER_ROOM_WEIGHT + ELITE_ROOM_WEIGHT + CAMPFIRE_ROOM_WEIGHT + SHOP_ROOM_WEIGHT
	random_room_type_weights[Room.Type.EVENT] = MONSTER_ROOM_WEIGHT + ELITE_ROOM_WEIGHT + CAMPFIRE_ROOM_WEIGHT + SHOP_ROOM_WEIGHT + EVENT_ROOM_WEIGHT

	random_room_type_total_weight = random_room_type_weights[Room.Type.EVENT]

func _setup_room_types() -> void:
	for room: Room in map_data[0]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.MONSTER
			room.battle_stats = battle_stats_pool.get_random_battle_for_tier(_tier_for("early"))
	
	#9th floor is always treasure
	for room: Room in map_data[FLOORS/2]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.TREASURE
	
	#last floor before boss is alwasy campfire
	for room: Room in map_data[FLOORS -2]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.CAMPFIRE
	
	for current_floor in map_data:
		for room: Room in current_floor:
			for next_room: Room in room.next_rooms:
				if next_room.type == Room.Type.NOT_ASSIGNED:
					_set_room_randomly(next_room)

func _set_room_randomly(room_to_set: Room) -> void:
	var campfire_below_4 := true
	var consecutive_campfire := true
	var consecutive_shop := true
	var campfire_on_13 := true
	var elite_too_early := true
	var consecutive_elite := true

	var type_candidate: Room.Type

	while campfire_below_4 or consecutive_campfire or consecutive_shop or campfire_on_13 or elite_too_early or consecutive_elite:
		type_candidate = _get_random_room_type_by_weight()

		var is_campfire := type_candidate == Room.Type.CAMPFIRE
		var has_campfire_parent := _room_has_parent_of_type(room_to_set, Room.Type.CAMPFIRE)
		var is_shop := type_candidate == Room.Type.SHOP
		var has_shop_parent := _room_has_parent_of_type(room_to_set, Room.Type.SHOP)
		var is_elite := type_candidate == Room.Type.ELITE_MONSTER
		var has_elite_parent := _room_has_parent_of_type(room_to_set, Room.Type.ELITE_MONSTER)

		campfire_below_4 = is_campfire and room_to_set.row < 3
		consecutive_campfire = is_campfire and has_campfire_parent
		consecutive_shop = is_shop and has_shop_parent
		campfire_on_13 = is_campfire and room_to_set.row == FLOORS -3
		# Elites only mid-act: give the player time to build a deck, and don't
		# crowd the campfire-on-13 prep floor.
		elite_too_early = is_elite and room_to_set.row < ELITE_MIN_ROW
		consecutive_elite = is_elite and has_elite_parent

	room_to_set.type = type_candidate

	if type_candidate == Room.Type.MONSTER:
		var role := "early" if room_to_set.row <= 2 else "late"
		room_to_set.battle_stats = battle_stats_pool.get_random_battle_for_tier(_tier_for(role))

	if type_candidate == Room.Type.ELITE_MONSTER:
		room_to_set.battle_stats = battle_stats_pool.get_random_elite_battle()

	if type_candidate == Room.Type.EVENT:
		room_to_set.event_scene = event_room_pool.get_random()

func _room_has_parent_of_type(room: Room, type: Room.Type) -> bool:
	var parents: Array[Room] = []
	# left parent
	if room.column > 0 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column - 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	# parent below
	if room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	# right parent
	if room.column < MAP_WIDTH-1 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column + 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	
	for parent: Room in parents:
		if parent.type == type:
			return true
	
	return false


# Tier number for the given role at the current act.
# Act 1 keeps the original two-tier ramp for regular monsters (0 then 1).
# Acts 2+ use one regular tier per act (placeholder until more content lands)
# and skip a tier between regulars and boss to leave room for "late"-only
# content authored later.
func _tier_for(role: String) -> int:
	var base := (act - 1) * 3
	match role:
		"early": return base
		"late":  return base + (1 if act == 1 else 0)
		"boss":  return base + 2
	return 0


func _get_random_room_type_by_weight() -> Room.Type:
	var roll := randf_range(0.0, random_room_type_total_weight)
	
	for type: Room.Type in random_room_type_weights:
		if random_room_type_weights[type] > roll:
			return type
	
	return Room.Type.MONSTER
