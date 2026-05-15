## Hardshell: passive on Shellbreaker. While the bearer has 0 block, incoming
## physical attacks deal 2 less damage. Once the bearer has any block, the
## bonus is gone — the player has "cracked the shell" and can chip the bearer
## normally until the shell goes back up.
##
## Implementation: a permanent ModifierValue on DMG_TAKEN whose flat_value is
## flipped between -2 and 0 by the bearer's stats_changed signal (which Stats
## fires whenever block, health, mana, or AP changes).
class_name HardshellStatus
extends Status

const REDUCTION := -2

var _bearer: Combatant = null
var _modifier: Modifier = null
var _bound_refresh: Callable


func get_tooltip() -> String:
	return tooltip


func initialize_status(target: Node) -> void:
	if target == null:
		return
	_bearer = target as Combatant
	if _bearer == null or _bearer.modifier_handler == null:
		return
	_modifier = _bearer.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	if _modifier == null:
		return
	var hardshell_value := ModifierValue.create_new_modifier("hardshell", ModifierValue.Type.FLAT)
	hardshell_value.flat_value = 0
	_modifier.add_new_value(hardshell_value)
	_bound_refresh = _refresh_modifier
	if _bearer.stats and not _bearer.stats.stats_changed.is_connected(_bound_refresh):
		_bearer.stats.stats_changed.connect(_bound_refresh)
	_refresh_modifier()


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _refresh_modifier() -> void:
	if _modifier == null or not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	var value := REDUCTION if _bearer.stats.block == 0 else 0
	_modifier.set_value_flat_value("hardshell", value)


func _exit_tree() -> void:
	if _modifier:
		_modifier.remove_value("hardshell")
	if _bearer and _bound_refresh and _bearer.stats:
		if _bearer.stats.stats_changed.is_connected(_bound_refresh):
			_bearer.stats.stats_changed.disconnect(_bound_refresh)
