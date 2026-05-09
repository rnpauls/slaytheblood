class_name BulwarkStatus
extends Status

# Granted by Tower Shield. Each START_OF_TURN, the wielder gains `stacks` block.
# Indefinite duration (can_expire = false) — lifetime is tied to weapon
# attach/detach, not turn count.

func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	if target and target.get("stats"):
		target.stats.block += stacks
	status_applied.emit(self)
