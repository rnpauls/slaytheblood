extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(dealer: Node, target: Node) -> String:
	return tooltip_text % Hook.get_damage(dealer, target, attack)

func apply_effects(targets: Array[Node]) -> void:
	Events.lock_hand.emit()
	var player_handler: PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	var custom_attack: int
	if await sixloot(player_handler, 1):
		custom_attack = attack + 2
	else:
		custom_attack = attack
	do_stock_attack_damage_effect(targets, custom_attack)
	Events.unlock_hand.emit()
