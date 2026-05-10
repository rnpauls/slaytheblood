## Big-zap finisher. Same routing as Aether Bolt — pure arcane, runechants
## fold in, no physical so block is irrelevant.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var rune_bonus := 0
	if owner and owner.status_handler:
		var rune := owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			rune_bonus = rune.consume()
	do_zap_effect(targets, modifiers, zap + rune_bonus)
