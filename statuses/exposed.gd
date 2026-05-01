class_name ExposedStatus
extends Status

const MODIFIER := 0.5

func get_tooltip() -> String:
	return tooltip % duration

func modify_damage_multiplicative(_dealer: Node, target: Node, _vp: ValueProp, ui: Node) -> float:
	if target == Status.get_status_owner(ui):
		return 1.0 + MODIFIER
	return 1.0

func after_turn_end(_side: String, ui: Node) -> void:
	if can_expire:
		duration -= 1
		status_changed.emit()
		if duration <= 0:
			ui.queue_free()
