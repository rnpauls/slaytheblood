extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if owner is Player:
		Events.lock_hand.emit()
	var custom_attack: int
	if await sixloot(owner, 1):
		custom_attack = attack + 2
	else:
		custom_attack = attack
	do_stock_attack_damage_effect(targets, modifiers, custom_attack)
	if owner is Player:
		Events.unlock_hand.emit()
