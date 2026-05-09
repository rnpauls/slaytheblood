## Pure cycler: discard 1 random card from hand (preferring atk ≥ 6 like
## sixloot), then draw 2 if the discard was a 6+, otherwise draw 1.
## Net: hand-neutral on a fail, +1 card on a hit, with a six-attack lost.
## Trades attack power for tempo — best when the hand is clogged with 6s.
extends Card


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner is Player:
		Events.lock_hand.emit()
	var discard := DiscardRandomSixEffect.new()
	discard.amount = 1
	var hit_six: bool = discard.execute([owner])
	var draw_count := 2 if hit_six else 1
	var card_draw := CardDrawEffect.new()
	card_draw.cards_to_draw = draw_count
	card_draw.execute([owner])
	if owner is Player:
		Events.unlock_hand.emit()
