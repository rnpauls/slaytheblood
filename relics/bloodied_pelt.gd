extends Relic

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")

var relic_ui: RelicUI
var activated_this_combat: bool = false


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.player_hit.connect(_on_player_hit)
	Events.player_initial_hand_drawn.connect(_reset_combat)


func _reset_combat() -> void:
	activated_this_combat = false


func _on_player_hit() -> void:
	if activated_this_combat:
		return
	activated_this_combat = true
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.status_handler:
		var empower := EMPOWER_STATUS.duplicate()
		empower.duration = 1
		empower.stacks = 4
		player.status_handler.add_status(empower)


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.disconnect(_on_player_hit)
	if Events.player_initial_hand_drawn.is_connected(_reset_combat):
		Events.player_initial_hand_drawn.disconnect(_reset_combat)
