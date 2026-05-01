class_name AttackDamageEffect
extends DamageEffect

var go_again:= false
var on_hit_effects: Array[OnHit]
## The combatant dealing the damage. Set by do_stock_attack_damage_effect.
var dealer: Node = null

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy:
			target.defend_attack(amount, go_again, on_hit_effects)
		if target is Enemy or target is Player:
			execute_single_target(target)

func execute_single_target(target: Node) -> void:
	var damage_dealt:=0
	if target is Enemy or target is Player:
		damage_dealt = target.take_damage(amount, receiver_modifier_type)
		SFXPlayer.play(sound)
	if (damage_dealt > 0):
		for on_hit in on_hit_effects:
			if on_hit.effect:
				on_hit.effect.execute([target])
			if on_hit.custom_func:
				on_hit.custom_func.call(target, on_hit.args)
		var ctx := {"damage": damage_dealt}
		Hook.on_hit_dealt(dealer, target, ctx)
		Hook.on_hit_received(dealer, target, ctx)
