## Marked: target takes +N damage from any source this turn. Mirrors
## EmpoweredStatus but lives on the receiving side (DMG_TAKEN), so it
## affects whoever hits the marked combatant — not whoever applied it.
class_name MarkedStatus
extends Status

var damage_taken_modifier: Modifier

var _target_ref: Node = null
var _bound_apply: Callable


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	_target_ref = target
	_bound_apply = apply_status.bind(target)
	damage_taken_modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	var mark_value := ModifierValue.create_new_modifier("marked", ModifierValue.Type.FLAT)
	mark_value.flat_value = stacks
	damage_taken_modifier.add_new_value(mark_value)
	if target is Player:
		Events.enemy_phase_ended.connect(_bound_apply)
	else:
		Events.player_turn_ended.connect(_bound_apply)


func update() -> void:
	damage_taken_modifier.set_value_flat_value("marked", stacks)


func apply_status(_target) -> void:
	status_applied.emit(self)


func _exit_tree() -> void:
	if damage_taken_modifier:
		damage_taken_modifier.remove_value("marked")
	if _bound_apply:
		if _target_ref is Player:
			if Events.enemy_phase_ended.is_connected(_bound_apply):
				Events.enemy_phase_ended.disconnect(_bound_apply)
		else:
			if Events.player_turn_ended.is_connected(_bound_apply):
				Events.player_turn_ended.disconnect(_bound_apply)
