class_name BrittleStatus
extends Status

var _block_modifier: Modifier

var _target_ref: Node = null
var _bound_apply: Callable


func get_tooltip() -> String:
	return tooltip % duration


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)

	_target_ref = target
	_bound_apply = apply_status.bind(target)

	_block_modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAINED)
	assert(_block_modifier, "No block gained modifier on %s" % target)

	var brittle_modifier_value := _block_modifier.get_value("brittle")

	if not brittle_modifier_value:
		brittle_modifier_value = ModifierValue.create_new_modifier("brittle", ModifierValue.Type.FLAT)
		brittle_modifier_value.flat_value = -1
		_block_modifier.add_new_value(brittle_modifier_value)

	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed)

	if target is Player:
		Events.enemy_phase_ended.connect(_bound_apply)
	else:
		Events.player_turn_ended.connect(_bound_apply)


func _on_status_changed() -> void:
	if duration <= 0 and _block_modifier:
		_block_modifier.remove_value("brittle")


func _exit_tree() -> void:
	if _bound_apply:
		if _target_ref is Player:
			if Events.enemy_phase_ended.is_connected(_bound_apply):
				Events.enemy_phase_ended.disconnect(_bound_apply)
		else:
			if Events.player_turn_ended.is_connected(_bound_apply):
				Events.player_turn_ended.disconnect(_bound_apply)
