## Read your current runechant stacks (without consuming) and grant that many
## Floodgate. Sets up a big payoff on the next arcane card.
extends Card

const FLOODGATE_STATUS = preload("res://statuses/floodgate.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.status_handler == null:
		return
	var rune := owner.status_handler.get_status_by_id("runechant") as RunechantStatus
	if rune == null:
		return
	var amount: int = rune.stacks
	if amount <= 0:
		return
	var fg := FLOODGATE_STATUS.duplicate()
	fg.stacks = amount
	owner.status_handler.add_status(fg)
