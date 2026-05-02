extends Weapon
	
const INTIMIDATE_STATUS = preload("res://statuses/intimidated.tres")

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack:int = attack) -> void:
	for enemy_target in targets:
		if enemy_target is Enemy and enemy_target.status_handler:
			var intimidate := INTIMIDATE_STATUS.duplicate()
			enemy_target.status_handler.add_status(intimidate)
	super.activate_weapon(targets, modifiers)
