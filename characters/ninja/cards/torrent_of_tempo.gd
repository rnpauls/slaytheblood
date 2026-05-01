extends Card

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(dealer: Node, target: Node) -> String:
	return tooltip_text % Hook.get_damage(dealer, target, attack)

func play(card_parent: Node, targets: Array[Node], char_stats: Stats) -> void:
	await super.play(card_parent, targets, char_stats)
	go_again = false

func apply_effects(targets: Array[Node]) -> void:
	var on_hit = OnHit.new()
	on_hit.custom_func = _on_hit_go_again
	on_hit.args = [self] as Array[Card]
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets)


func _on_hit_go_again(_target: Node, args: Array[Card]):
	args[0].go_again = true
