class_name IraPendantRelic
extends Relic

var relic_ui: RelicUI
var activated_this_turn := false

func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.player_attack_completed.connect(activate_relic.bind(owner))
	Events.player_end_phase_started.connect(reset)


func activate_relic(_owner: RelicUI) -> void:
	if activated_this_turn:
		return
	
	activated_this_turn = true
	relic_ui.flash()
	var status_handler : StatusHandler = relic_ui.get_tree().get_first_node_in_group('player').status_handler
	#for status_ui: StatusUI in status_handler.get_children(): #Don't have a good way to remove status_ui by id
		#if status_ui.status.id == "empowered" and status_ui.status.duration < 2:
			#status_ui.queue_free()
	var old_emp_status = status_handler._get_status("empowered")
	if old_emp_status:
		await old_emp_status.status_applied
	
	var empowered_status = preload("res://statuses/empowered.tres").duplicate()
	empowered_status.duration = 1
	empowered_status.stacks = 1
	status_handler.add_status(empowered_status)



func deactivate_relic(_owner: RelicUI) -> void:
	#Events.shop_entered.disconnect(add_shop_modifier)
	Events.player_attack_completed.disconnect(activate_relic)
	Events.player_end_phase_started.disconnect(reset)
	pass

func reset() -> void:
	activated_this_turn = 0
	#remove_modifier()

#func remove_modifier() -> void:
	#var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	#var damage_modifier := player.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	#damage_modifier.remove_value("ira_pendant")

#func add_shop_modifier(shop: Shop) -> void:
	#relic_ui.flash()
	#
	#var shop_cost_modifier := shop.modifier_handler.get_modifier(Modifier.Type.SHOP_COST)
	#assert(shop_cost_modifier, "No shop cost modifier in shop!")
	#
	##Safety check if we already have it
	#var coupons_modifier_value := shop_cost_modifier.get_value("coupons")
	#
	#if not coupons_modifier_value:
		#coupons_modifier_value = ModifierValue.create_new_modifier("coupons", ModifierValue.Type.PERCENT_BASED)
		#coupons_modifier_value.percent_value = -1 * discount /100.0
		#shop_cost_modifier.add_new_value(coupons_modifier_value)

# we can provide unique tooltips per relic if we want to
func get_tooltip() -> String:
	return tooltip
