## Splitter: passive on a slime-style enemy. The first time the bearer takes
## damage that drops them to or below half HP (without killing them), spawn
## two Mini-Slime allies flanking the bearer. One-shot per battle.
##
## type=EVENT_BASED — driven entirely by the Events.combatant_damaged signal,
## which fires after the damage actually lands (post-block subtraction). Killing
## blow is intentionally not a split: spawning allies on a 0-HP host is a
## confusing "but the enemy died right?" moment.
class_name SplitterStatus
extends Status

const MINI_SLIME_STATS := preload("res://enemies/slime/mini_slime_enemy.tres")
const SPAWN_OFFSETS: Array[Vector2] = [Vector2(-110, -20), Vector2(110, -20)]

var _has_split: bool = false
var _bearer: Enemy = null
var _bound_check: Callable


func get_tooltip() -> String:
	if _has_split:
		return tooltip + " (already split)"
	return tooltip


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	_bound_check = _on_combatant_damaged
	Events.combatant_damaged.connect(_bound_check)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_combatant_damaged(victim: Node, _attacker: Node, _damage: int) -> void:
	if _has_split:
		return
	if victim != _bearer:
		return
	if not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	if _bearer.stats.health <= 0:
		# Killed by this hit — no allies appear from a corpse.
		return
	var half_hp := float(_bearer.stats.max_health) / 2.0
	if float(_bearer.stats.health) > half_hp:
		return
	_has_split = true
	_spawn_minis()


func _spawn_minis() -> void:
	var handler := _bearer.get_parent()
	if handler == null or not handler.has_method("spawn_enemy"):
		return
	var base_pos := _bearer.position
	for off in SPAWN_OFFSETS:
		handler.spawn_enemy(MINI_SLIME_STATS, base_pos + off)


func _exit_tree() -> void:
	if _bound_check and Events.combatant_damaged.is_connected(_bound_check):
		Events.combatant_damaged.disconnect(_bound_check)
