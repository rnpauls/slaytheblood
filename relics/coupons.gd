class_name CouponsRelic
extends Relic

@export_range(1,100) var discount := 50

var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	Events.shop_entered.connect(add_shop_modifier)
	relic_ui = relic_ui_node


func activate_relic(_relic_ui: RelicUI) -> void:
	# Triggered by Relic.Type at the matching turn-phase. Coupons is
	# EVENT_BASED — handled via add_shop_modifier on shop_entered instead.
	pass


func deactivate_relic(_relic_ui: RelicUI) -> void:
	Events.shop_entered.disconnect(add_shop_modifier)

func add_shop_modifier(shop: Shop) -> void:
	relic_ui.flash()

	var shop_cost_modifier := shop.modifier_handler.get_modifier(Modifier.Type.SHOP_COST)
	assert(shop_cost_modifier, "No shop cost modifier in shop!")

	#Safety check if we already have it
	var coupons_modifier_value := shop_cost_modifier.get_value("coupons")

	if not coupons_modifier_value:
		coupons_modifier_value = ModifierValue.create_new_modifier("coupons", ModifierValue.Type.PERCENT_BASED)
		coupons_modifier_value.percent_value = -1 * discount /100.0
		shop_cost_modifier.add_new_value(coupons_modifier_value)

# we can provide unique tooltips per relic if we want to
func get_tooltip() -> String:
	return tooltip
