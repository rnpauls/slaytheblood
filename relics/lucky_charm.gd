extends Relic

var relic_ui: RelicUI
var used_this_combat: bool = false


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.card_pitched.connect(_on_card_pitched)
	Events.player_initial_hand_drawn.connect(_reset_combat)


func _reset_combat() -> void:
	used_this_combat = false


func _on_card_pitched(_card: Card) -> void:
	if used_this_combat:
		return
	used_this_combat = true
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.player_handler:
		player.player_handler.draw_card()


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.card_pitched.is_connected(_on_card_pitched):
		Events.card_pitched.disconnect(_on_card_pitched)
	if Events.player_initial_hand_drawn.is_connected(_reset_combat):
		Events.player_initial_hand_drawn.disconnect(_reset_combat)
