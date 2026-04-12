extends Card

func apply_block_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	super.apply_block_effects(targets, _modifiers)
	return 

func get_default_tooltip() -> String:
	return tooltip_text % defense

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text % defense
