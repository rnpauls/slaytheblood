class_name BrittleStatus
extends Status

var _block_modifier: Modifier


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)

	_block_modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAINED)
	assert(_block_modifier, "No block gained modifier on %s" % target)

	var brittle_modifier_value := _block_modifier.get_value("brittle")

	if not brittle_modifier_value:
		brittle_modifier_value = ModifierValue.create_new_modifier("brittle", ModifierValue.Type.FLAT)
		brittle_modifier_value.flat_value = -stacks
		_block_modifier.add_new_value(brittle_modifier_value)

	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed)

	if target is Player:
		Events.enemy_phase_ended.connect(apply_status.bind(target))
	else:
		Events.player_turn_ended.connect(apply_status.bind(target))


func update() -> void:
	if _block_modifier == null:
		return
	var brittle_modifier_value := _block_modifier.get_value("brittle")
	if brittle_modifier_value:
		brittle_modifier_value.flat_value = -stacks


func _on_status_changed() -> void:
	if duration <= 0 and _block_modifier:
		_block_modifier.remove_value("brittle")
