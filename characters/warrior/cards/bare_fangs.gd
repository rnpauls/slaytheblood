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
	var player_handler: PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	var custom_attack: int
	if await rampage(player_handler, 1):
		custom_attack = attack + 2
	else:
		custom_attack = attack
	do_stock_attack_damage_effect(targets, modifiers, custom_attack)
	Events.unlock_hand.emit()

func _on_card_discarded(card: Card) -> void:
	discarded_card = card

func rampage(source: Node, qty: int) -> bool:
	Events.card_discarded.connect(_on_card_discarded)
	#var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	source.draw_card()
	discarded_card = null
	var discard_effect = DiscardRandomEffect.new()
	discard_effect.amount = qty
	discard_effect.execute([source])
	#var discarded_card: Card = await Events.card_discarded
	var timer = source.get_tree().create_timer(.01)
	await timer.timeout
	if discarded_card and (discarded_card.attack >= 6):
		return true
	else:
		return false
