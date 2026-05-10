## Apply the Channel: Time Warp status. Fires at next start-of-turn —
## bonus cards on top of the normal hand draw. Pairs with Channel: Meteor
## to load up a "huge next turn" with both a damage primer and the cards
## to enable a follow-up.
extends Card

const CHANNEL_STATUS = preload("res://statuses/channel_time_warp.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.status_handler == null:
		return
	var s := CHANNEL_STATUS.duplicate()
	s.duration = 1
	owner.status_handler.add_status(s)
