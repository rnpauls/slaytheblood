## AoE runechant detonator. Consume the runechant pile once, then deal that
## amount of arcane to each enemy. Same total per-enemy damage as a Runechant
## attack would deliver, but spread across the room — strong against swarms.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var consumed := 0
	if owner and owner.status_handler:
		var rune := owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			consumed = rune.consume()
	if consumed <= 0:
		return
	do_zap_effect(targets, modifiers, consumed)
