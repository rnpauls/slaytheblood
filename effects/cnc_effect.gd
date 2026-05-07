class_name CncEffect
extends Effect


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if target is Combatant and target.hand_facade:
			target.hand_facade.destroy_arsenal()
