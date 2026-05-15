extends Card

## Pure-arcane NAA: fires `zap` through ZapEffect (bypasses block, scaled by
## ARCANE_DEALT). The zap-only counterpart to vanilla_attack.gd. No runechant
## consumption — that's the auto-rider's job on physical attacks.
func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_zap_effect(targets, modifiers, zap)
