extends Card


# Flicker Step is player-only by design — the sink/draw flow uses an
# interactive "choose cards in hand" UI prompt that has no enemy equivalent.
# If we ever want an enemy version, swap to a random pick + draw_pile insert.
func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not (owner is Player):
		return
	var ui_layer = owner.get_tree().get_first_node_in_group("ui_layer")
	if ui_layer == null:
		return
	var cards_to_sink: Array[CardUI] = await ui_layer.choose_cards_in_hand(2)
	for card_ui in cards_to_sink:
		card_ui.sink()
	if owner.hand_facade:
		owner.hand_facade.draw_cards(1)
