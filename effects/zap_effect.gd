## Zap N: deal N arcane damage to a target. Fires through the existing
## DamageEffect pipeline with damage_kind = ARCANE, so it bypasses block and
## is mitigated by mana spend in Stats.take_damage. Fires on-hit effects when
## arcane damage actually lands (after mana prevention) — symmetric with
## AttackDamageEffect, so split-damage cards like aether_conduit can trigger
## their on-hit on either component independently.
##
## Does NOT emit Events.combatant_attacked — that's the physical-attack-declared
## signal (Thorns / on-block reflectors). Zap is still bypass-block by design.
class_name ZapEffect
extends DamageEffect

var on_hit_effects: Array[OnHit]
## Attacker reference (the Combatant whose card produced the packet). Used by
## reactive defensive effects — propagated from DamagePacket.source_owner.
var source_owner: Node = null

func _init() -> void:
	damage_kind = Card.DamageKind.ARCANE

func execute_single_target(target: Node) -> void:
	var damage_dealt := 0
	if target is Enemy or target is Player:
		damage_dealt = target.take_damage(amount, receiver_modifier_type, damage_kind, prevention)
		SFXRegistry.play_stream(sound)
	if damage_dealt > 0:
		Events.combatant_damaged.emit(target, source_owner, damage_dealt)
		# Arcane bypasses block, so the float is never the BLOCK variant.
		Events.damage_floated.emit(target, damage_dealt, Card.DamageKind.ARCANE, false)
		for on_hit in on_hit_effects:
			if on_hit.effect:
				on_hit.effect.execute([target])
			if on_hit.custom_func:
				on_hit.custom_func.call(target, on_hit.args)
