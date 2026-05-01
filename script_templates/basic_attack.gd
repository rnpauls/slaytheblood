extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(dealer: Node, target: Node) -> String:
	return tooltip_text % Hook.get_damage(dealer, target, attack)

func apply_effects(targets: Array[Node]) -> void:
	do_stock_attack_damage_effect(targets)
