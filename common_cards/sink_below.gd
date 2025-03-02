extends Card

#func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	#var block_effect := BlockEffect.new()
	#block_effect.amount = defense
	#block_effect.sound = sound
	#block_effect.execute(targets)

func get_default_tooltip() -> String:
	return tooltip_text % defense

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text % defense
