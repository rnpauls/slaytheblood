extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var mod_def := modifiers.get_modified_value(defense, Modifier.Type.BLOCK_GAINED)
	targets[0].stats.block += mod_def
