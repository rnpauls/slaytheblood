class_name AttackDamageEffect
extends DamageEffect

var go_again:= false
var on_hit_effects: Array[OnHit]

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		# Block-declaration only applies to physical attacks; arcane bypasses block
		# entirely and is mitigated by mana spend in Stats.take_damage.
		if target is Enemy and damage_kind == Card.DamageKind.PHYSICAL:
			target.defend_attack(amount, go_again, on_hit_effects)
		if target is Enemy or target is Player:
			execute_single_target(target)

func execute_single_target(target: Node) -> void:
	var damage_dealt:=0
	if target is Enemy or target is Player:
		damage_dealt = target.take_damage(amount, receiver_modifier_type, damage_kind, prevention)
		SFXPlayer.play(sound)
	if (damage_dealt > 0):
		for on_hit in on_hit_effects:
			if on_hit.effect:
				on_hit.effect.execute([target])
			if on_hit.custom_func:
				on_hit.custom_func.call(target, on_hit.args)
