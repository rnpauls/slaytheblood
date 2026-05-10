## Apply the Channel: Aegis status. Defensive Channel — fires at next
## start-of-turn, granting a fat block chunk that survives whatever the
## enemies were planning.
extends Card

const CHANNEL_STATUS = preload("res://statuses/channel_aegis.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.status_handler == null:
		return
	var s := CHANNEL_STATUS.duplicate()
	s.duration = 1
	owner.status_handler.add_status(s)
