class_name IraPendantRelic
extends Relic

var relic_ui: RelicUI
var attacks_this_turn := 0

func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	Events.player_attack_declared.connect(activate_relic.bind(null))
	Events.player_end_phase_started.connect(reset)


func activate_relic(_owner: RelicUI) -> void:
	if attacks_this_turn == 1:
		relic_ui.flash()
		var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
		var damage_modifier := player.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
		var dmg_modifier_value = ModifierValue.create_new_modifier("ira_pendant", ModifierValue.Type.FLAT)
		dmg_modifier_value.flat_value = 1
		damage_modifier.add_new_value(dmg_modifier_value)
	if attacks_this_turn > 1:
		remove_modifier()
	attacks_this_turn += 1


func deactivate_relic(_owner: RelicUI) -> void:
	#Events.shop_entered.disconnect(add_shop_modifier)
	Events.player_attack_declared.disconnect(activate_relic)
	Events.player_end_phase_started.disconnect(reset)
	pass

func reset() -> void:
	attacks_this_turn = 0
	remove_modifier()

func remove_modifier() -> void:
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	var damage_modifier := player.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	damage_modifier.remove_value("ira_pendant")

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
