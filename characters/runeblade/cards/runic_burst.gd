## Runechant detonator — single target. Consume the entire runechant pile and
## deal 2× consumed as arcane damage. Pure spell, fired through ZapEffect so
## it bypasses block (the runeblade's whole pitch).
##
## Unlike attacks, this consumes runechants OUTSIDE of build_attack_packet —
## bypassing card.gd's automatic 1× consumption — so we control the multiplier.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var consumed := 0
	if owner and owner.status_handler:
		var rune := owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			consumed = rune.consume()
	if consumed <= 0:
		return
	do_zap_effect(targets, modifiers, 2 * consumed)
