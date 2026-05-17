extends Relic

@export var block_bonus := 4
@export var mana_bonus := 1


func activate_relic(relic_ui: RelicUI) -> void:
	var player := self.owner as Player
	if not player or not player.stats:
		return
	if player.stats.attacks_this_turn != 0:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block_bonus
	block_effect.execute([player])

	Events.player_action_phase_started.connect(_grant_mana.bind(relic_ui), CONNECT_ONE_SHOT)
	relic_ui.flash()


func _grant_mana(relic_ui: RelicUI) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.stats:
		player.stats.mana += mana_bonus
