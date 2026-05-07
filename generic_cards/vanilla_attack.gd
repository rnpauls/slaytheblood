extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	# do_stock_attack_damage_effect now builds a DamagePacket that already
	# folds in `zap` and any runechants — no separate do_zap_effect call.
	do_stock_attack_damage_effect(targets, modifiers)
