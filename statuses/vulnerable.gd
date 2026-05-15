## Vulnerable: permanent (battle-long) +50% incoming damage. Unlike Marked
## (FLAT +N, this-turn) and Exposed (also temporary), Vulnerable sticks
## around once applied — multiple applications don't compound (stack_type
## NONE) so the player can't accidentally crush a single target by stacking
## Mark of Pain ten times.
##
## Affects both physical and arcane (no only_physical flag) — Vulnerable is a
## "soft target" debuff conceptually.
class_name VulnerableStatus
extends Status

const PERCENT_INCREASE := 0.5

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
	# Re-applying simply refreshes — add_status with NONE stack_type skips the
	# duplicate, but if it somehow lands twice we don't want to add 2x percent.
	if _modifier.get_value("vulnerable") != null:
		return
	var vuln_value := ModifierValue.create_new_modifier("vulnerable", ModifierValue.Type.PERCENT_BASED)
	vuln_value.percent_value = PERCENT_INCREASE
	_modifier.add_new_value(vuln_value)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _exit_tree() -> void:
	if _modifier:
		_modifier.remove_value("vulnerable")
