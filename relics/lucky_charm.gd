extends Relic

var relic_ui: RelicUI
var used_this_combat: bool = false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.card_pitched.connect(_on_card_pitched)
	Events.player_initial_hand_drawn.connect(_reset_combat)


func _reset_combat() -> void:
	used_this_combat = false


func _on_card_pitched(_card: Card) -> void:
	if used_this_combat:
		return
	used_this_combat = true
	relic_ui.flash()
	var player_handler: PlayerHandler = relic_ui.get_tree().get_first_node_in_group("player_handler")
	if player_handler:
		player_handler.draw_card()


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.card_pitched.is_connected(_on_card_pitched):
		Events.card_pitched.disconnect(_on_card_pitched)
	if Events.player_initial_hand_drawn.is_connected(_reset_combat):
		Events.player_initial_hand_drawn.disconnect(_reset_combat)
