## Channel: Aegis — at the bearer's next START_OF_TURN, grant a fat block
## chunk. Defensive Channel option: "I survive next turn for sure" payoff
## for the cost of one casting turn.
class_name ChannelAegisStatus
extends Status

@export var block_amount: int = 15


func get_tooltip() -> String:
	return tooltip % block_amount


func initialize_status(_target: Node) -> void:
	pass


func apply_status(target: Node) -> void:
	if target and target.stats:
		target.stats.block += block_amount
	status_applied.emit(self)
