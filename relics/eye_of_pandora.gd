extends Relic

var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.player_card_drawn.connect(_on_player_card_drawn)


func _on_player_card_drawn(card: Card) -> void:
	if not card:
		return
	card.cost = randi_range(0, 3)
	card.pitch = randi_range(0, 3)
	if relic_ui:
		relic_ui.flash()


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.player_card_drawn.is_connected(_on_player_card_drawn):
		Events.player_card_drawn.disconnect(_on_player_card_drawn)
