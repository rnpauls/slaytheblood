## Channel: Time Warp — at the bearer's next START_OF_TURN, draw extra
## cards on top of the normal hand draw. Synergizes with the Channel build's
## tempo profile: spend a turn casting, dump big the next turn.
class_name ChannelTimeWarpStatus
extends Status

@export var cards_to_draw: int = 3


func get_tooltip() -> String:
	return tooltip % cards_to_draw


func initialize_status(_target: Node) -> void:
	pass


func apply_status(target: Node) -> void:
	if target and target is Combatant and target.hand_facade:
		target.hand_facade.draw_cards(cards_to_draw)
	status_applied.emit(self)
