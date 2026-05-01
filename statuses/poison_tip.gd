class_name PoisonTipStatus
extends Status

var _consumed := false

func get_tooltip() -> String:
	return tooltip % stacks

func on_hit_dealt(dealer: Node, target: Node, _ctx: Dictionary, ui: Node) -> void:
	if dealer != Status.get_status_owner(ui) or _consumed:
		return
	_consumed = true
	var dmg_eff := DamageEffect.new()
	dmg_eff.amount = stacks
	dmg_eff.execute([target])

func after_attack_completed(attacker: Node, _ctx: Dictionary, ui: Node) -> void:
	if attacker == Status.get_status_owner(ui) and _consumed:
		ui.queue_free()

func after_turn_end(_side: String, ui: Node) -> void:
	ui.queue_free()
