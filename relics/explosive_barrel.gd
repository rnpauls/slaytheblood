extends Relic

@export var damage := 2

func after_turn_end(side: String, ui: Node) -> void:
	if side == "enemy":
		var enemies := ui.get_tree().get_nodes_in_group("enemies")
		var damage_effect := DamageEffect.new()
		damage_effect.amount = damage
		damage_effect.execute(enemies)
		ui.flash()
