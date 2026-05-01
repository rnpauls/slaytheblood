extends Relic

@export var block_bonus := 3

func after_turn_end(side: String, ui: Node) -> void:
	if side == "player":
		var player := ui.get_tree().get_nodes_in_group("player")
		if player:
			var block_effect := BlockEffect.new()
			block_effect.amount = block_bonus
			block_effect.execute(player)
			ui.flash()
