## Aura: Command — Warlord passive. While the bearer is alive, every OTHER
## ally enemy gains a permanent +1 DMG_DEALT modifier. Subscribes to
## Events.enemy_spawned so mid-fight reinforcements (slime splits, future
## summons) also pick up the buff.
##
## The bearer itself is intentionally excluded — Aura: Command is a leader
## buff for the rank-and-file. Kill the Warlord first and the grunts lose
## their teeth.
class_name AuraCommandStatus
extends Status

const DMG_BONUS := 1
const SOURCE := "aura_command"

var _bearer: Enemy = null
var _bound_on_spawn: Callable


func get_tooltip() -> String:
	return tooltip


func initialize_status(target: Node) -> void:
	if not target is Enemy:
		return
	_bearer = target as Enemy
	# Buff every living ally already on the field.
	for n in _all_enemies():
		_apply_to_ally(n)
	# Hook future spawns so mid-fight reinforcements join the buff.
	_bound_on_spawn = _on_enemy_spawned
	if not Events.enemy_spawned.is_connected(_bound_on_spawn):
		Events.enemy_spawned.connect(_bound_on_spawn)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_enemy_spawned(new_enemy: Enemy) -> void:
	if new_enemy == _bearer:
		return
	_apply_to_ally(new_enemy)


func _apply_to_ally(ally: Node) -> void:
	if ally == _bearer:
		return
	if not (ally is Combatant and ally.modifier_handler and ally.stats and ally.stats.health > 0):
		return
	var modifier: Modifier = ally.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	if modifier == null:
		return
	if modifier.get_value(SOURCE) != null:
		return  # already applied
	var value := ModifierValue.create_new_modifier(SOURCE, ModifierValue.Type.FLAT)
	value.flat_value = DMG_BONUS
	modifier.add_new_value(value)


func _remove_from_ally(ally: Node) -> void:
	if ally == _bearer:
		return
	if not (ally is Combatant and ally.modifier_handler):
		return
	var modifier: Modifier = ally.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	if modifier != null:
		modifier.remove_value(SOURCE)


func _all_enemies() -> Array:
	if not is_instance_valid(_bearer) or not _bearer.is_inside_tree():
		return []
	return _bearer.get_tree().get_nodes_in_group("enemies")


func _exit_tree() -> void:
	# Warlord died (or status was removed). Strip the buff from every ally
	# so survivors no longer get the leadership bonus.
	for n in _all_enemies():
		_remove_from_ally(n)
	if _bound_on_spawn and Events.enemy_spawned.is_connected(_bound_on_spawn):
		Events.enemy_spawned.disconnect(_bound_on_spawn)
