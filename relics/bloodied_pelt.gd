extends Relic

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")

var relic_ui: RelicUI
var activated_this_combat: bool = false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.player_hit.connect(_on_player_hit)
	Events.player_initial_hand_drawn.connect(_reset_combat)


func _reset_combat() -> void:
	activated_this_combat = false


func _on_player_hit() -> void:
	if activated_this_combat:
		return
	activated_this_combat = true
	relic_ui.flash()
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if player and player.status_handler:
		var empower := EMPOWER_STATUS.duplicate()
		empower.duration = 1
		empower.stacks = 4
		player.status_handler.add_status(empower)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.disconnect(_on_player_hit)
	if Events.player_initial_hand_drawn.is_connected(_reset_combat):
		Events.player_initial_hand_drawn.disconnect(_reset_combat)
