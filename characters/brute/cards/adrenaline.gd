extends Card


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	targets[0].stats.action_points += 1
	targets[0].stats.health -= 2
