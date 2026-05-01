class_name MuscleStatus
extends Status

func get_tooltip() -> String:
	return tooltip % stacks

func modify_damage_additive(dealer: Node, _target: Node, _vp: ValueProp, ui: Node) -> int:
	if dealer == Status.get_status_owner(ui):
		return stacks
	return 0
