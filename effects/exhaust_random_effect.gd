class_name ExhaustRandomEffect
extends Effect

var amount := 1


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if target is Combatant and target.hand_facade:
			target.hand_facade.exhaust_random(amount)
