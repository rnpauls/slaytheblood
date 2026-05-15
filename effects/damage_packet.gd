## Bundled damage profile for an attack — physical and arcane in one shot, so
## the defender (and the enemy AI) can reason about the full hit before any
## of it resolves. Runechants are folded into `arcane` at build time, so a
## single Runic Spike with 3 runechants on the field arrives as one packet
## of {physical: 3, arcane: 5}, not three separate damage events.
##
## execute() resolves defense once via EnemyAI.defend_packet (which picks the
## best block/pitch allocation across the hand, considering both portions of
## the hit together), then routes physical through AttackDamageEffect and
## arcane through ZapEffect with the chosen prevention amount. Both effects
## carry the same on_hit_effects, so a split-damage card like aether_conduit
## can trigger its on-hit independently for the physical land and the arcane
## land (drawing up to two cards). Splitting the decision per damage type was
## the old shape — it caused the enemy to die to {phys + arc} totals when
## neither portion was lethal alone.
class_name DamagePacket
extends RefCounted

var physical: int = 0
var arcane: int = 0
var source_card: Card = null
var source_owner: Node = null
var sound: AudioStream = null
var go_again: bool = false
var on_hit_effects: Array[OnHit] = []
## Set at packet build time when source has Unblockable status (and the status
## is past its fresh-window). Forwarded into AttackDamageEffect so block
## subtraction is skipped for the physical hit. The status itself is consumed
## here in execute_single_target after the swing is dispatched.
var ignore_block: bool = false

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		execute_single_target(target)

func execute_single_target(target: Node) -> void:
	# Single defensive decision per packet. Enemy AI commits block + pitch
	# in one shot before either damage stage runs; player path stays on the
	# default prevention=-1 (auto-spend mana on arcane).
	var prevention := -1
	if target is Enemy and target.enemy_ai:
		var result: Dictionary = target.enemy_ai.defend_packet(self)
		target.defense_sequencer.animate_defense(result)
		prevention = int(result.get("prevention", 0))

	if physical > 0:
		var atk := AttackDamageEffect.new()
		atk.amount = physical
		atk.damage_kind = Card.DamageKind.PHYSICAL
		atk.sound = sound
		atk.go_again = go_again
		atk.on_hit_effects = on_hit_effects
		atk.source_owner = source_owner
		atk.ignore_block = ignore_block
		atk.execute([target])
		# Consume one Unblockable stack now that the swing has dispatched.
		# Multiple Telegraph Strikes pile to multiple stacks — each one buys a
		# single ignore-block swing.
		if ignore_block and source_owner and source_owner.status_handler:
			var u := source_owner.status_handler.get_status_by_id("unblockable") as UnblockableStatus
			if u:
				u.consume()
	if arcane > 0:
		var zap := ZapEffect.new()
		zap.amount = arcane
		zap.sound = sound
		zap.prevention = prevention
		zap.on_hit_effects = on_hit_effects
		zap.source_owner = source_owner
		zap.execute([target])
