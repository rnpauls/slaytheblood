## AoE arcane bolt. Runechants fold in once and split across all targets
## (do_zap_effect uses the same amount per target — choose if that's the
## intended balance or if runechants should be reserved for single-target).
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var rune_bonus := 0
	if owner and owner.status_handler:
		var rune := owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			rune_bonus = rune.consume()
	do_zap_effect(targets, modifiers, zap + rune_bonus)
