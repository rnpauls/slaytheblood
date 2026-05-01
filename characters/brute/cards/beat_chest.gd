extends Card

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")
const INTIMIDATE_STATUS = preload("res://statuses/intimidated.tres")

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	# Apply Empower 3 to the player (card owner).
	var player: Node = owner
	if player and player.status_handler:
		var empower := EMPOWER_STATUS.duplicate()
		empower.stacks = 3
		empower.duration = 1
		player.status_handler.add_status(empower)

	# Apply Intimidate 1 to the targeted enemy.
	for enemy_target in targets:
		if enemy_target is Enemy and enemy_target.status_handler:
			var intimidate := INTIMIDATE_STATUS.duplicate()
			enemy_target.status_handler.add_status(intimidate)
