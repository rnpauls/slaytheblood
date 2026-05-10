## Apply the Channel: Meteor status to self. Fires at next start-of-turn
## (or earlier via Quickened Cast).
extends Card

const CHANNEL_STATUS = preload("res://statuses/channel_meteor.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.status_handler == null:
		return
	var s := CHANNEL_STATUS.duplicate()
	s.duration = 1
	owner.status_handler.add_status(s)
