extends Relic

@export var mana_gain := 3


func activate_relic(relic_ui: RelicUI) -> void:
	var player := self.owner as Player
	if not player or not player.player_handler:
		return

	var hand := player.player_handler.hand
	if hand and hand.get_child_count() > 0:
		var card_uis := hand.get_children()
		var random_card_ui = RNG.array_pick_random(card_uis)
		if random_card_ui and random_card_ui.has_method("discard"):
			random_card_ui.discard()

	if player.stats:
		player.stats.mana += mana_gain
	relic_ui.flash()
