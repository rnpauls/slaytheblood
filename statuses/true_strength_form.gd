class_name TrueStrengthStatus
extends Status

const MUSCLE_STATUS = preload("res://statuses/muscle.tres")

var stacks_per_turn := 2

func after_turn_end(side: String, ui: Node) -> void:
	# Fires at the start of the player's turn (enemy phase just ended).
	if side == "enemy":
		var target := Status.get_status_owner(ui)
		if not target:
			return
		var status_effect := StatusEffect.new()
		var muscle := MUSCLE_STATUS.duplicate()
		muscle.stacks = stacks_per_turn
		status_effect.status = muscle
		status_effect.execute([target])
