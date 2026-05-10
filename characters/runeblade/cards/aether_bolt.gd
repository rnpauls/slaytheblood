## Pure-arcane staple. No physical component — fired through ZapEffect, so
## it bypasses block entirely (the Spellweaver's whole identity).
## Runechants on the runeblade still get consumed if any are stored: card.gd's
## build_attack_packet does NOT run for NAA cards, so we route through
## do_zap_effect manually and consume runechants ourselves.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var rune_bonus := 0
	if owner and owner.status_handler:
		var rune := owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			rune_bonus = rune.consume()
	do_zap_effect(targets, modifiers, zap + rune_bonus)
