extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(dealer: Node, target: Node) -> String:
	return tooltip_text % Hook.get_damage(dealer, target, attack)

func apply_effects(targets: Array[Node]) -> void:
	var top_card_arr := owner.stats.draw_pile.reveal_top_cards(1)
	var top_pitch := 0
	if top_card_arr.is_empty():
		print_debug("rabble on empty deck")
	else:
		top_pitch = top_card_arr[0].pitch
		print_debug("Revealed %s to rabble" % top_card_arr[0].id)
	do_stock_attack_damage_effect(targets, attack - top_pitch)
