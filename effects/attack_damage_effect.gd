class_name AttackDamageEffect
extends DamageEffect

var go_again:= false
var on_hit_effects: Array[OnHit]
## Attacker reference (the Combatant whose card produced the packet). Used by
## reactive defensive effects (Thorns, retaliation relics) — propagated from
## DamagePacket.source_owner.
var source_owner: Node = null
## Set by DamagePacket when the source has Unblockable status. Forwarded into
## Stats.take_damage so block subtraction is skipped for this swing.
var ignore_block: bool = false

func execute(targets: Array[Node]) -> void:
	# Defense (block/pitch decision) is resolved upstream in
	# DamagePacket.execute_single_target — by the time we reach here,
	# stats.block / stats.mana are already populated. We only land damage.
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			execute_single_target(target)

func execute_single_target(target: Node) -> void:
	var damage_dealt:=0
	if target is Enemy or target is Player:
		damage_dealt = target.take_damage(amount, receiver_modifier_type, damage_kind, prevention, ignore_block)
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
