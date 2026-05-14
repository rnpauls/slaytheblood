extends Relic

const TRIGGER_THRESHOLD: int = 5

var relic_ui: RelicUI
var cards_played: int = 0


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.player_card_played.connect(_on_card_played)
	relic_ui.set_counter(cards_played)


func _on_card_played(_card: Card) -> void:
	cards_played += 1
	if cards_played >= TRIGGER_THRESHOLD:
		cards_played = 0
		relic_ui.flash()
		var player := self.owner as Player
		if player and player.player_handler:
			player.player_handler.draw_card()
	relic_ui.set_counter(cards_played)


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.player_card_played.is_connected(_on_card_played):
		Events.player_card_played.disconnect(_on_card_played)
