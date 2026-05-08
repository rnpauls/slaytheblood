extends Card


func apply_effects(_targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not owner:
		return
	var mod_def := modifiers.get_modified_value(defense, Modifier.Type.BLOCK_GAINED)
	owner.stats.block += mod_def
