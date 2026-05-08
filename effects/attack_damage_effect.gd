class_name AttackDamageEffect
extends DamageEffect

var go_again:= false
var on_hit_effects: Array[OnHit]
## Attacker reference (the Combatant whose card produced the packet). Used by
## reactive defensive effects (Thorns, retaliation relics) — propagated from
## DamagePacket.source_owner.
var source_owner: Node = null

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
		# combatant_attacked fires for every physical attack, even fully-blocked
		# ones, so on-block reflectors (Thorns / Spiked Pauldrons) can punish the
		# attempt. combatant_damaged below is gated on residual damage and is
		# the right signal for "I actually got hit" reactions.
		Events.combatant_attacked.emit(target, source_owner, amount, damage_dealt)
	if (damage_dealt > 0):
		Events.combatant_damaged.emit(target, source_owner, damage_dealt)
		for on_hit in on_hit_effects:
			if on_hit.effect:
				on_hit.effect.execute([target])
			if on_hit.custom_func:
				on_hit.custom_func.call(target, on_hit.args)
