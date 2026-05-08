extends Relic

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")

var relic_ui: RelicUI
var took_damage_this_turn: bool = false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.player_hit.connect(_on_player_hit)
	Events.player_initial_hand_drawn.connect(_reset_flag)


func _on_player_hit() -> void:
	took_damage_this_turn = true


func _reset_flag() -> void:
	took_damage_this_turn = false


func activate_relic(owner: RelicUI) -> void:
	if took_damage_this_turn:
		took_damage_this_turn = false
		return
	owner.flash()
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player and player.status_handler:
		var rune := RUNECHANT_STATUS.duplicate()
		rune.stacks = 1
		player.status_handler.add_status(rune)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.disconnect(_on_player_hit)
	if Events.player_initial_hand_drawn.is_connected(_reset_flag):
		Events.player_initial_hand_drawn.disconnect(_reset_flag)
