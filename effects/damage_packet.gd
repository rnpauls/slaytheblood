## Bundled damage profile for an attack — physical and arcane in one shot, so
## the defender (and the enemy AI in Phase 5) can reason about the full hit
## before any of it resolves. Runechants are folded into `arcane` at build
## time, so a single Runic Spike with 3 runechants on the field arrives as
## one packet of {physical: 3, arcane: 5}, not three separate damage events.
##
## execute() routes the physical portion through AttackDamageEffect (which
## still triggers defend_attack and on-hit effects) and the arcane portion
## through ZapEffect. Phase 5 will hook a reactive AI decision in here to
## pre-deduct prevention before the arcane damage lands.
class_name DamagePacket
extends RefCounted

var physical: int = 0
var arcane: int = 0
var source_card: Card = null
var source_owner: Node = null
var sound: AudioStream = null
var go_again: bool = false
var on_hit_effects: Array[OnHit] = []

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		execute_single_target(target)

func execute_single_target(target: Node) -> void:
	if physical > 0:
		var atk := AttackDamageEffect.new()
		atk.amount = physical
		atk.damage_kind = Card.DamageKind.PHYSICAL
		atk.sound = sound
		atk.go_again = go_again
		atk.on_hit_effects = on_hit_effects
		atk.source_owner = source_owner
		atk.execute([target])
	if arcane > 0:
		# Arcane reaction window: enemy AI gets to decide how much to prevent
		# (and pitch cards if needed) before the damage lands. Player defaults
		# to -1 (auto-spend everything available) — manual UI is a future hook.
		var prevention := -1
		if target is Enemy and target.enemy_ai:
			prevention = target.enemy_ai.decide_arcane_prevention(self)
		var zap := ZapEffect.new()
		zap.amount = arcane
		zap.sound = sound
		zap.prevention = prevention
		zap.execute([target])
