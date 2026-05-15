## Two consecutive zaps. Floodgate (if active) buffs BOTH hits because
## FloodgateStatus._arm_decay is call_deferred — the decay signal isn't wired
## up until after apply_effects returns, so both do_zap_effect calls run with
## the ARCANE_DEALT modifier active.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_zap_effect(targets, modifiers, zap)
	do_zap_effect(targets, modifiers, zap)
