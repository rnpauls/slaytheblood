class_name OnHitDamageEffect
extends AttackDamageEffect

var on_hit_effect: Effect
var on_hit_callable: Callable
var args: Array

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy:
			target.defend_attack(amount, go_again)
		if target is Enemy or target is Player:
			execute_single_target(target)

func execute_single_target(target: Node) -> void:
	var damage_dealt:=0
	if target is Enemy or target is Player:
		damage_dealt = target.take_damage(amount, receiver_modifier_type)
		SFXPlayer.play(sound)
	if (damage_dealt > 0):
		if on_hit_effect:
			on_hit_effect.execute([target])
		if on_hit_callable:
			on_hit_callable.call(target, args)
