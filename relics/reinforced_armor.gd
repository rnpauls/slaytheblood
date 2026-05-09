extends Relic

@export var block_bonus := 3

func activate_relic(relic_ui: RelicUI) -> void:
	if not self.owner:
		return
	var block_effect := BlockEffect.new()
	block_effect.amount = block_bonus
	block_effect.execute([self.owner])

	relic_ui.flash()
