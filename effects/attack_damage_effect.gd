class_name AttackDamageEffect
extends DamageEffect

var go_again:= false

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy:
			target.defend_attack(amount, go_again)
		if target is Enemy or target is Player:
			super.execute_single_target(target)
