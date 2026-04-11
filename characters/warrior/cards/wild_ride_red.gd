extends Card

var discarded_card: Card = null

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	Events.lock_hand.emit()
	Events.card_discarded.connect(_on_card_discarded)
	var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	var player_handler: PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	player_handler.draw_card()
	#var discarded_card: Card = player_handler.discard_cards(1)
	var discard_effect = DiscardRandomEffect.new()
	discard_effect.amount = 1
	discard_effect.execute(targets)
	#var discarded_card: Card = await Events.card_discarded
	if discarded_card:
		if discarded_card.attack >= 6:
			go_again = true
		else:
			go_again = false
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)
	Events.unlock_hand.emit()

func _on_card_discarded(card: Card) -> void:
	discarded_card = card
