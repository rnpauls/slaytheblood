## Tighter Flicker Step: sink 1, draw 2 (instead of sink 2, draw 1).
## Player-only — sink uses an interactive hand-pick UI; if we ever want
## an enemy version we'd swap to a random-pick + draw_pile insert.
extends Card


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not (owner is Player):
		return
	var ui_layer = owner.get_tree().get_first_node_in_group("ui_layer")
	if ui_layer == null:
		return
	var cards_to_sink: Array[CardUI] = await ui_layer.choose_cards_in_hand(1)
	for card_ui in cards_to_sink:
		card_ui.sink()
	if owner.hand_facade:
		owner.hand_facade.draw_cards(2)
