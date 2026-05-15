class_name EmpoweredStatus
extends Status

var damage_modifier: Modifier

var _target_ref: Node = null
var _bound_apply: Callable

#Adds "stacks" to next attack power
#Set duration to 2 if created by an attack (it will reduce duration by 1 when attack is completed)

func get_tooltip() -> String:
	return tooltip % stacks

func initialize_status(target: Node) -> void:
	_target_ref = target
	_bound_apply = apply_status.bind(target)
	damage_modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	var dmg_modifier_value: ModifierValue = ModifierValue.create_new_modifier("empowered", ModifierValue.Type.FLAT)
	dmg_modifier_value.flat_value = stacks
	damage_modifier.add_new_value(dmg_modifier_value)
	target.attack_completed.connect(_bound_apply)
	if target is Player:
		Events.player_turn_ended.connect(_bound_apply)
	else:
		Events.enemy_phase_ended.connect(_bound_apply)

	print_debug("Add empowered modifier")

func update() -> void:
	damage_modifier.set_value_flat_value("empowered", stacks)

func apply_status(_target) -> void:
	status_applied.emit(self)

func _exit_tree() -> void:
	damage_modifier.remove_value("empowered")
	if _bound_apply:
		if _target_ref is Player:
			if Events.player_turn_ended.is_connected(_bound_apply):
				Events.player_turn_ended.disconnect(_bound_apply)
		else:
			if Events.enemy_phase_ended.is_connected(_bound_apply):
				Events.enemy_phase_ended.disconnect(_bound_apply)
