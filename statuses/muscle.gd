class_name MuscleStatus
extends Status

# Muscle is permanent flat damage by default. To grant a "+N strength
# this turn" effect (e.g. Berserker Helm, Bloodrush), call the static
# helper apply_temporary() — it adds N stacks AND records them as
# temporary so they tick off again at end of turn.
var temp_stacks: int = 0

var _target: Node = null
var _is_player_target: bool = false


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	_target = target
	_is_player_target = target is Player
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)

	# Hook turn-end so any temporary stacks added via add_temporary() decay.
	if _is_player_target:
		Events.player_turn_ended.connect(_on_turn_ended)
	else:
		Events.enemy_phase_ended.connect(_on_turn_ended)


func _on_status_changed(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)

	var dmg_dealt_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	assert(dmg_dealt_modifier, "No dmg dealt modifier on %s" % target)

	var muscle_modifier_value := dmg_dealt_modifier.get_value("muscle")

	if not muscle_modifier_value:
		muscle_modifier_value = ModifierValue.create_new_modifier("muscle", ModifierValue.Type.FLAT)

	muscle_modifier_value.flat_value = stacks
	dmg_dealt_modifier.add_new_value(muscle_modifier_value)


# Apply N stacks of Muscle that decay at end of turn. Use this anywhere
# "+N strength this turn" is wanted — bypasses creating a separate status.
static func apply_temporary(handler: StatusHandler, amount: int) -> void:
	if amount <= 0:
		return
	var template: MuscleStatus = load("res://statuses/muscle.tres").duplicate()
	template.stacks = amount
	handler.add_status(template)
	var live := handler.get_status_by_id("muscle") as MuscleStatus
	if live:
		live.temp_stacks += amount


func _on_turn_ended() -> void:
	if temp_stacks <= 0:
		return
	var to_remove := temp_stacks
	temp_stacks = 0
	stacks -= to_remove


func _exit_tree() -> void:
	if _is_player_target:
		if Events.player_turn_ended.is_connected(_on_turn_ended):
			Events.player_turn_ended.disconnect(_on_turn_ended)
	else:
		if Events.enemy_phase_ended.is_connected(_on_turn_ended):
			Events.enemy_phase_ended.disconnect(_on_turn_ended)
	if _target:
		var dmg_modifier: Modifier = _target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
		if dmg_modifier:
			dmg_modifier.remove_value("muscle")
