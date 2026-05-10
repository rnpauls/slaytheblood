## Runechants are stored arcane charge on a combatant. Visually they appear as
## small sprites floating above the owner; mechanically they consume on the
## owner's next attack and add +1 arcane damage per stack to that attack's
## DamagePacket. The rider arcane lands as part of the same packet, so it
## also triggers any on-hit effects on the attacking card (e.g. concuss with
## runechants discards twice — once from the physical hit, once from the
## arcane rider).
##
## INTENSITY-stacked: each "stack" is one runechant. When stacks reach 0 the
## StatusUI auto-removes itself (see status_ui.gd:37) and our _exit_tree
## cleans up any remaining sprites.
class_name RunechantStatus
extends Status

const RUNECHANT_SCENE := preload("res://scenes/runechant/runechant.tscn")
const SPRITE_OFFSET_Y := -110.0
const SPRITE_STRIDE_X := 22.0
const VISIBLE_CAP := 8

var _target: Node = null
var _sprites: Array[Node2D] = []

func initialize_status(target: Node) -> void:
	_target = target
	if not status_changed.is_connected(_refresh_sprites):
		status_changed.connect(_refresh_sprites)
	_refresh_sprites()

## Pop all runechants. Caller fires arcane damage with the returned amount.
## Setting stacks to 0 triggers StatusUI auto-removal (status_ui.gd:37–38)
## which then triggers our _exit_tree to despawn any remaining sprites.
func consume() -> int:
	var amount := stacks
	stacks = 0
	return amount

func _refresh_sprites() -> void:
	if _target == null:
		return
	# Collapse beyond VISIBLE_CAP — show one sprite as the "many runechants" badge.
	var visible_count: int = mini(stacks, VISIBLE_CAP)
	while _sprites.size() > visible_count:
		var sprite: Node2D = _sprites.pop_back()
		if is_instance_valid(sprite):
			sprite.queue_free()
	while _sprites.size() < visible_count:
		var sprite: Node2D = RUNECHANT_SCENE.instantiate()
		_target.add_child(sprite)
		_sprites.append(sprite)
	_layout_sprites()

func _layout_sprites() -> void:
	if _sprites.is_empty():
		return
	var n: int = _sprites.size()
	var center_offset: float = (n - 1) * 0.5 * SPRITE_STRIDE_X
	for i in n:
		var sprite: Node2D = _sprites[i]
		if not is_instance_valid(sprite):
			continue
		sprite.position = Vector2(i * SPRITE_STRIDE_X - center_offset, SPRITE_OFFSET_Y)

func _exit_tree() -> void:
	for sprite in _sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_sprites.clear()
