extends Relic

@export var damage := 2

func activate_relic(relic_ui: RelicUI) -> void:
	# get_nodes_in_group("enemies") is an unbounded set lookup (not the
	# fragile single-player pattern) — keeping it here is intentional, see
	# the get_first_node_in_group removal plan.
	var enemies := relic_ui.get_tree().get_nodes_in_group("enemies")
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	damage_effect.execute(enemies)

	relic_ui.flash()
