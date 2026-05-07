extends Card

const TRASH_CARD := preload("res://generic_cards/trash.tres")

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if targets.is_empty() or not targets[0]:
		return
	var effect := CardAddEffect.new()
	effect.card_to_add = TRASH_CARD
	effect.destination = CardAddEffect.Destination.DRAW_PILE_RANDOM
	effect.execute([targets[0]])
