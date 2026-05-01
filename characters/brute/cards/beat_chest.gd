extends Card

const INTIMIDATE_STATUS = preload("res://statuses/intimidated.tres")
const EMPOWERED_STATUS = preload("res://statuses/empowered.tres")

func apply_effects(targets: Array[Node]) -> void:
	# Apply Empower 3 to the player (card owner).
	var empowered := EMPOWERED_STATUS.duplicate()
	empowered.stacks = 3
	owner.status_handler.add_status(empowered)

	# Apply Intimidate 1 to the targeted enemy.
	for enemy_target in targets:
		if enemy_target is Enemy and enemy_target.status_handler:
			var intimidate := INTIMIDATE_STATUS.duplicate()
			enemy_target.status_handler.add_status(intimidate)
