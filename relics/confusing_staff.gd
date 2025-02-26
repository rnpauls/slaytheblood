extends Relic

var relic_ui: RelicUI

func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.player_card_drawn.connect(_on_player_card_drawn)

func activate_relic(owner: RelicUI) -> void:
	
	
func _on_player_card_drawn() -> void:
	var player_handler = owner.get_tree().get_first_node_in_group("player_handler") as PlayerHandler
