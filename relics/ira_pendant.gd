class_name IraPendantRelic
extends Relic

var relic_ui: RelicUI
var activated_this_turn := false

func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.player_attack_completed.connect(activate_relic.bind(relic_ui_node))
	Events.player_end_phase_started.connect(reset)


func activate_relic(_relic_ui: RelicUI) -> void:
	if activated_this_turn:
		return

	activated_this_turn = true
	relic_ui.flash()
	var player := self.owner as Player
	if not player or not player.status_handler:
		return
	var status_handler: StatusHandler = player.status_handler
	var old_emp_status = status_handler.get_status_by_id("empowered")
	if old_emp_status:
		await old_emp_status.status_applied

	var empowered_status = preload("res://statuses/empowered.tres").duplicate()
	empowered_status.duration = 1
	empowered_status.stacks = 1
	status_handler.add_status(empowered_status)



func deactivate_relic(_relic_ui: RelicUI) -> void:
	Events.player_attack_completed.disconnect(activate_relic)
	Events.player_end_phase_started.disconnect(reset)


func reset() -> void:
	activated_this_turn = false


# we can provide unique tooltips per relic if we want to
func get_tooltip() -> String:
	return tooltip
