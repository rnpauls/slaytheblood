## Crippled: per-stack penalty to the bearer's outgoing damage. Duration and
## intensity are coupled (like Bleed) — duration ticks down by 1 at the bearer's
## end of turn, and the modifier follows along (Crippled 2 → -2 dmg, then -1, gone).
##
## Implementation note: type=END_OF_TURN so apply_statuses_by_type fires apply_status
## at the bearer's end of turn. The handler then decrements duration via
## _on_status_applied; status_changed fires here and refreshes (or removes) the
## DMG_DEALT modifier value to match the new duration.
class_name CrippledStatus
extends Status

var damage_dealt_modifier: Modifier
var _target_ref: Node = null


func get_tooltip() -> String:
	return tooltip % duration


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	_target_ref = target
	damage_dealt_modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	assert(damage_dealt_modifier, "No DMG_DEALT modifier on %s" % target)
	var crippled_value := ModifierValue.create_new_modifier("crippled", ModifierValue.Type.FLAT)
	crippled_value.flat_value = -duration
	damage_dealt_modifier.add_new_value(crippled_value)
	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed)


func update() -> void:
	# Called when the status is re-added (DURATION stacking sums durations).
	if damage_dealt_modifier:
		damage_dealt_modifier.set_value_flat_value("crippled", -duration)


func apply_status(_target: Node) -> void:
	# StatusHandler decrements duration after this returns; _on_status_changed
	# refreshes (or removes) the modifier as the new duration takes effect.
	status_applied.emit(self)


func _on_status_changed() -> void:
	if not damage_dealt_modifier:
		return
	if duration <= 0:
		damage_dealt_modifier.remove_value("crippled")
	else:
		damage_dealt_modifier.set_value_flat_value("crippled", -duration)


func _exit_tree() -> void:
	if damage_dealt_modifier:
		damage_dealt_modifier.remove_value("crippled")
