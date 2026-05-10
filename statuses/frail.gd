class_name FrailStatus
extends Status

var MODIFIER := -0.5

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)

	var block_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAINED)
	assert(block_modifier, "No block gained modifier on %s" % target)

	var frail_modifier_value := block_modifier.get_value("frail")

	if not frail_modifier_value:
		frail_modifier_value = ModifierValue.create_new_modifier("frail", ModifierValue.Type.PERCENT_BASED)
		frail_modifier_value.percent_value = MODIFIER
		block_modifier.add_new_value(frail_modifier_value)

	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed.bind(block_modifier))


func _on_status_changed(block_modifier: Modifier) -> void:
	if duration <= 0 and block_modifier:
		block_modifier.remove_value("frail")
