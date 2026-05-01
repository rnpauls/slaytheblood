extends Card

const EMPOWERED_STATUS = preload("res://statuses/empowered.tres")

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(dealer: Node, target: Node) -> String:
	return tooltip_text % Hook.get_damage(dealer, target, attack)

func apply_effects(targets: Array[Node]) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = func(atk_target: Node, _args: Array) -> void:
		if not atk_target:
			return
		var empowered := EMPOWERED_STATUS.duplicate()
		empowered.stacks = 1
		owner.status_handler.add_status(empowered)
	on_hits.append(on_hit)

	do_stock_attack_damage_effect(targets)
