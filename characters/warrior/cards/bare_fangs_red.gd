extends Card

var discarded_card: CardUI = null
func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	Events.lock_hand.emit()
	var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	var player_handler: PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	player_handler.draw_card()
	#var discarded_card: Card = player_handler.discard_cards(1)
	var discard_effect = DiscardRandomEffect.new()
	discard_effect.amount = 1
	discard_effect.execute(targets)
	var discarded_cards = await Events.card_discarded
	discarded_card = discarded_cards[0]
	if discarded_card:
		if discarded_card.attack >= 6:
			attack += 2
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)
	Events.unlock_hand.emit()
