extends Card


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if await sixloot(owner, 1):
		go_again = true
		owner.hand_facade.draw_cards(2)
		MuscleStatus.apply_temporary(owner.status_handler, 2)
