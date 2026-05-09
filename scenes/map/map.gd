class_name Map
extends Node2D

const SCROLL_SPEED := 60
const MAP_ROOM = preload("res://scenes/map/map_room.tscn")
const MAP_LINE = preload("res://scenes/map/map_line.tscn")

const LEGEND_ENTRIES := [
	[Room.Type.MONSTER, "Monster"],
	[Room.Type.ELITE_MONSTER, "Elite"],
	[Room.Type.EVENT, "Event"],
	[Room.Type.CAMPFIRE, "Campfire"],
	[Room.Type.SHOP, "Shop"],
	[Room.Type.TREASURE, "Treasure"],
	[Room.Type.BOSS, "Boss"],
]
const LEGEND_ICON_SIZE := Vector2(28, 28)

@onready var map_generator: MapGenerator = $MapGenerator
@onready var visuals: Node2D = $Visuals
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var camera_2d: Camera2D = $Camera2D
@onready var legend: CanvasLayer = %Legend
@onready var legend_rows: VBoxContainer = %LegendRows
@onready var current_room_marker: Sprite2D = %CurrentRoomMarker

var map_data: Array[Array]
var floors_climbed: int
var last_room: Room
var camera_edge_y: float
var scroll_locked := false

func _ready() -> void:
	camera_edge_y = MapGenerator.Y_DIST * (MapGenerator.FLOORS -1)
	_populate_legend()


func _populate_legend() -> void:
	for entry: Array in LEGEND_ENTRIES:
		var type: Room.Type = entry[0]
		var icon_texture: Texture2D = MapRoom.ICONS[type][0]
		if icon_texture == null:
			continue

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.custom_minimum_size = LEGEND_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var label := Label.new()
		label.text = entry[1]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)

		legend_rows.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or scroll_locked:
		return

	if event.is_action_pressed("scroll_down"):
		camera_2d.position.y -= SCROLL_SPEED

	if event.is_action_pressed("scroll_up"):
		camera_2d.position.y += SCROLL_SPEED

	if event is InputEventPanGesture:
		camera_2d.position.y -= event.delta.y * SCROLL_SPEED

	camera_2d.position.y = clampf(camera_2d.position.y, -camera_edge_y, 0)

func generate_new_map() -> void:
	floors_climbed = 0
	map_data = map_generator.generate_map()
	create_map()

func load_map(map: Array[Array], floors_completed: int, last_room_climbed: Room) -> void:
	floors_climbed = floors_completed
	map_data = map
	last_room = last_room_climbed
	create_map()

	if floors_climbed > 0:
		camera_2d.position.y = clampf(-floors_climbed * MapGenerator.Y_DIST, -camera_edge_y, 0)
	else:
		unlock_floor()

func create_map() -> void:
	for current_floor: Array in map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	#boss room has no next room
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(map_data[MapGenerator.FLOORS - 1][middle])

	var map_width_pixels := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) / 2
	visuals.position.y = get_viewport_rect().size.y / 2


func unlock_floor(which_floor: int = floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			map_room.available = true


func unlock_next_rooms() -> void:
	for map_room: MapRoom in rooms.get_children():
		if last_room.next_rooms.has(map_room.room):
			map_room.available = true


func unlock_all_rooms() -> void:
	for map_room: MapRoom in rooms.get_children():
		map_room.available = true


func show_current_marker(room: Room) -> void:
	current_room_marker.position = room.position + Vector2(0, -50)
	current_room_marker.visible = true


func hide_current_marker() -> void:
	current_room_marker.visible = false


func show_map() -> void:
	show()
	camera_2d.enabled = true
	legend.visible = true


func hide_map() -> void:
	hide()
	camera_2d.enabled = false
	legend.visible = false


func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.clicked.connect(_on_map_room_clicked)
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)
	
	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return
		
	for next: Room in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		new_map_line.add_point(room.position)
		new_map_line.add_point(next.position)
		lines.add_child(new_map_line)


func _on_map_room_clicked(room: Room) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false


func _on_map_room_selected(room: Room) -> void:
	last_room = room
	floors_climbed += 1
	Events.map_exited.emit(room)
