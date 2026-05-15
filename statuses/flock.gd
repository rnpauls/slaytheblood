## Flock: Pack Bat passive. Bearer's outgoing physical attacks gain +1 damage
## per OTHER living enemy with the same character_name (the "flock"). Recounts
## via Events.enemy_died — when a member of the flock dies, every survivor's
## bonus drops; the last bat alive is back to baseline damage.
##
## Identifies flock-mates by stats.character_name match. Cheap and good enough
## while the only flock-style enemy is Pack Bat — switch to a group lookup if
## a second flock species ever ships.
class_name FlockStatus
extends Status

const PER_ALLY := 1

var _bearer: Enemy = null
var _modifier: Modifier = null
var _bound_refresh_on_death: Callable
var _flock_name: String = ""


func get_tooltip() -> String:
	var allies := _count_allies()
	return tooltip % allies


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	if _bearer.modifier_handler == null or _bearer.stats == null:
		return
	_flock_name = _bearer.stats.character_name
	_modifier = _bearer.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	if _modifier == null:
		return
	var flock_value := ModifierValue.create_new_modifier("flock", ModifierValue.Type.FLAT)
	flock_value.flat_value = 0
	_modifier.add_new_value(flock_value)
	_bound_refresh_on_death = _on_enemy_died
	if not Events.enemy_died.is_connected(_bound_refresh_on_death):
		Events.enemy_died.connect(_bound_refresh_on_death)
	# Initial count happens after the bearer has joined the tree, so all
	# flock-mates spawned in the same setup pass are already siblings.
	call_deferred("_refresh_modifier")


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _count_allies() -> int:
	if not is_instance_valid(_bearer) or not _bearer.is_inside_tree():
		return 0
	var count := 0
	for n in _bearer.get_tree().get_nodes_in_group("enemies"):
		if n == _bearer:
			continue
		if n is Enemy and n.stats and n.stats.character_name == _flock_name and n.stats.health > 0:
			count += 1
	return count


func _on_enemy_died(_dead: Enemy) -> void:
	# Defer so the dying enemy is fully removed before we recount.
	call_deferred("_refresh_modifier")


func _refresh_modifier() -> void:
	if _modifier == null or not is_instance_valid(_bearer):
		return
	var allies := _count_allies()
	_modifier.set_value_flat_value("flock", allies * PER_ALLY)
	status_changed.emit()  # refresh tooltip


func _exit_tree() -> void:
	if _modifier:
		_modifier.remove_value("flock")
	if _bound_refresh_on_death and Events.enemy_died.is_connected(_bound_refresh_on_death):
		Events.enemy_died.disconnect(_bound_refresh_on_death)
