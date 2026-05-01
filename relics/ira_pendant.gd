class_name IraPendantRelic
extends Relic

const EMPOWERED_STATUS = preload("res://statuses/empowered.tres")

var _activated_this_turn := false

func after_attack_completed(attacker: Node, _ctx: Dictionary, ui: Node) -> void:
	var player := ui.get_tree().get_first_node_in_group("player")
	if attacker != player or _activated_this_turn:
		return
	_activated_this_turn = true
	var empowered := EMPOWERED_STATUS.duplicate()
	empowered.stacks = 1
	player.status_handler.add_status(empowered)
	ui.flash()

func after_turn_end(side: String, _ui: Node) -> void:
	if side == "player":
		_activated_this_turn = false

func get_tooltip() -> String:
	return tooltip
