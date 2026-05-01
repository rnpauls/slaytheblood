class_name Modifier
extends Node

enum Type {DMG_DEALT, DMG_TAKEN, CARD_COST, SHOP_COST, NO_MODIFIER, BLOCK_GAINED}

@export var type: Type

func get_value(source: String) -> ModifierValue:
	for value: ModifierValue in get_children():
		if value.source == source:
			return value
	
	return null

func set_value_flat_value(source:String, new_flat_val: int) -> void:
	for value: ModifierValue in get_children():
		if value.source == source:
			value.flat_value = new_flat_val
			return
	print_debug("Failed to find flat_value %s" % source)

func add_new_value(value: ModifierValue) -> void:
	var modifier_value := get_value(value.source)
	if not modifier_value:
		add_child(value)
	else:
		modifier_value.flat_value = value.flat_value
		modifier_value.percent_value = value.percent_value

func remove_value(source: String) -> void:
	for value: ModifierValue in get_children():
		if value.source == source:
			value.queue_free()

func clear_values() -> void:
	for value: ModifierValue in get_children():
		value.queue_free()

func get_modified_value(base: int) -> int:
	var flat_result: int = base
	var percent_result: float = 1.0
	#Apply flat first
	for value: ModifierValue in get_children():
		if value.type == ModifierValue.Type.FLAT:
			flat_result += value.flat_value
	
	for value: ModifierValue in get_children():
		if value.type == ModifierValue.Type.PERCENT_BASED:
			percent_result += value.percent_value
	
	return floori(flat_result * percent_result)
