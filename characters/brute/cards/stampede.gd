## Rampage attack with draw payoff. Always draws 1 baseline; if rampage hits
## (the discarded card had attack ≥ 6) draws 2 more. Net: draw 1 (rampage
## fail) or draw 3 + discard 1 (rampage hit) = +2 cards.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if owner is Player:
		Events.lock_hand.emit()
	var bonus_draw := 2 if await sixloot(owner, 1) else 0
	# Baseline draw 1 happens regardless. sixloot already drew 1 + discarded 1,
	# so we just add the extra on success.
	var card_draw := CardDrawEffect.new()
	card_draw.cards_to_draw = bonus_draw
	if bonus_draw > 0:
		card_draw.execute([owner])
	do_stock_attack_damage_effect(targets, modifiers)
	if owner is Player:
		Events.unlock_hand.emit()
