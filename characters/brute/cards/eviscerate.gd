extends Card

const INTIMIDATE_STATUS = preload("res://statuses/intimidated.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:

	for enemy_target in targets:
		if enemy_target is Enemy and enemy_target.status_handler:
			var intimidate := INTIMIDATE_STATUS.duplicate()
			enemy_target.status_handler.add_status(intimidate)
	
	do_stock_attack_damage_effect(targets, modifiers)
