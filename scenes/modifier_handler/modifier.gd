class_name Modifier
extends Node

enum Type {DMG_DEALT, DMG_TAKEN, CARD_COST, SHOP_COST, NO_MODIFIER, BLOCK_GAINED, ARCANE_DEALT}

## Fires whenever a ModifierValue is added, removed, or mutated. Used by
## ModifierHandler.modifiers_changed to drive hand/weapon UI refreshes so the
## "Empowered grew from 2 to 3" case still ticks the display even though no
## child entered/exited the tree.
signal value_changed

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
			value_changed.emit()
			return
	print_debug("Failed to find flat_value %s" % source)

func add_new_value(value: ModifierValue) -> void:
	var modifier_value := get_value(value.source)
	if not modifier_value:
		add_child(value)
	else:
		modifier_value.flat_value = value.flat_value
		modifier_value.percent_value = value.percent_value
	value_changed.emit()

func remove_value(source: String) -> void:
	for value: ModifierValue in get_children():
		if value.source == source:
			value.queue_free()
	value_changed.emit.call_deferred()

func clear_values() -> void:
	for value: ModifierValue in get_children():
		value.queue_free()
	value_changed.emit.call_deferred()

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
