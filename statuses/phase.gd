## Phase: Wraith passive. Reduces incoming PHYSICAL damage by 2 (clamped so the
## bearer can't heal off attacks). Arcane is unaffected — that's the point of
## the status, and the only_physical flag on the underlying ModifierValue
## handles the kind filtering.
class_name PhaseStatus
extends Status

const REDUCTION := -2

var _bearer: Combatant = null
var _modifier: Modifier = null


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
	var phase_value := ModifierValue.create_new_modifier("phase", ModifierValue.Type.FLAT)
	phase_value.flat_value = REDUCTION
	phase_value.only_physical = true
	_modifier.add_new_value(phase_value)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _exit_tree() -> void:
	if _modifier:
		_modifier.remove_value("phase")
