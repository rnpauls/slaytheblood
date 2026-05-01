class_name EmpoweredStatus
extends Status

## Whether the current attack has consumed this empowered instance.
## Set true in modify_damage_additive so after_attack_completed knows to remove it.
var _consumed := false

func get_tooltip() -> String:
	return tooltip % stacks

func modify_damage_additive(dealer: Node, _target: Node, _vp: ValueProp, ui: Node) -> int:
	if dealer == Status.get_status_owner(ui) and not _consumed:
		_consumed = true
		return stacks
	return 0

func after_attack_completed(attacker: Node, _ctx: Dictionary, ui: Node) -> void:
	if attacker == Status.get_status_owner(ui) and _consumed:
		ui.queue_free()

func after_turn_end(_side: String, ui: Node) -> void:
	ui.queue_free()
