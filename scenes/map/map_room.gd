class_name MapRoom
extends Area2D

signal clicked(room: Room)
signal selected(room: Room)

const ICONS := {
	Room.Type.NOT_ASSIGNED: [null, Vector2.ONE],
	Room.Type.MONSTER: [preload("res://art/tile_0103.png"), Vector2.ONE*5],
	Room.Type.TREASURE: [preload("res://art/tile_0089.png"), Vector2.ONE*4],
	Room.Type.CAMPFIRE: [preload("res://art/player_heart.png"), Vector2.ONE*3.5],
	Room.Type.SHOP: [preload("res://art/gold.png"), Vector2.ONE*3],
	Room.Type.BOSS: [preload("res://art/bone3.png"), Vector2.ONE*5],
	Room.Type.EVENT: [preload("res://art/rarity.png"), Vector2.ONE*5],
	# Reuse the boss sprite at a slightly smaller scale for elites — visually
	# louder than a regular monster, distinct from the boss.
	Room.Type.ELITE_MONSTER: [preload("res://art/tile_0118.png"), Vector2.ONE*4],
}

const HOVER_SCALE := Vector2(1.4, 1.4)
const HOVER_TWEEN_IN := 0.1
const HOVER_TWEEN_OUT := 0.15

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visuals: Node2D = $Visuals

var available := false : set = set_available
var room: Room : set = set_room
var _hover_tween: Tween


func set_available(new_value: bool) -> void:
	available = new_value

	if available:
		animation_player.play("highlight")
		animation_player.seek(randf() * animation_player.current_animation_length, true)
	elif not room.selected:
		_kill_hover_tween()
		z_index = 0
		animation_player.play("RESET")

func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(0, 360)
	sprite_2d.texture = ICONS[room.type][0]
	sprite_2d.scale = ICONS[room.type][1]

func show_selected() -> void:
	line_2d.modulate = Color.WHITE

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return
	
	room.selected = true
	clicked.emit(room)
	SFXRegistry.play(Constants.SFX_CLICK_BUTTON)
	animation_player.play("select")
	get_viewport().set_input_as_handled()

#Called by animationplayer when the "select" animation finishes
func _on_map_room_selected() -> void:
	selected.emit(room)


func _on_mouse_entered() -> void:
	if not available:
		return
	SFXRegistry.play(Constants.SFX_HOVER_UI)
	# Map rooms are Area2D (not BaseButton), so CursorManager's auto-attach
	# can't catch them, and set_default_cursor_shape doesn't trigger an
	# immediate cursor refresh while the mouse is already inside the
	# Area2D's collision. Swap the texture bound to CURSOR_ARROW directly —
	# this updates the displayed cursor on the same frame.
	if CursorManager.POINTER:
		Input.set_custom_mouse_cursor(CursorManager.POINTER, Input.CURSOR_ARROW,
			CursorManager.POINTER_HOTSPOT)
	z_index = 1
	animation_player.stop()
	_kill_hover_tween()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(visuals, "scale", HOVER_SCALE, HOVER_TWEEN_IN)


func _on_mouse_exited() -> void:
	if not available:
		return
	# Restore the arrow texture on the ARROW shape.
	if CursorManager.ARROW:
		Input.set_custom_mouse_cursor(CursorManager.ARROW, Input.CURSOR_ARROW,
			CursorManager.ARROW_HOTSPOT)
	_kill_hover_tween()
	z_index = 0
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(visuals, "scale", Vector2.ONE, HOVER_TWEEN_OUT)
	_hover_tween.tween_callback(func(): animation_player.play("highlight"))


func _kill_hover_tween() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
