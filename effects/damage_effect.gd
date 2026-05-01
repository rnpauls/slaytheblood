class_name DamageEffect
extends Effect

var amount:= 0

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		execute_single_target(target)

func execute_single_target(target: Node) -> void:
	if target is Enemy or target is Player:
		target.take_damage(amount)
		SFXPlayer.play(sound)
