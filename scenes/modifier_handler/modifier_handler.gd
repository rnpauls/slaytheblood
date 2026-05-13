class_name ModifierHandler
extends Node

## Fires whenever any child Modifier's values are added, removed, or mutated,
## OR a Modifier child itself enters/exits the tree. Listeners (hand cards,
## weapon UI) refresh their modifier-tinted labels in response.
signal modifiers_changed

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	for m in get_children():
		if m is Modifier and not m.value_changed.is_connected(_on_modifier_value_changed):
			m.value_changed.connect(_on_modifier_value_changed)

func _on_child_entered(node: Node) -> void:
	if node is Modifier and not node.value_changed.is_connected(_on_modifier_value_changed):
		node.value_changed.connect(_on_modifier_value_changed)
	modifiers_changed.emit.call_deferred()

func _on_child_exiting(_node: Node) -> void:
	modifiers_changed.emit.call_deferred()

func _on_modifier_value_changed() -> void:
	modifiers_changed.emit()

func has_modifier(type: Modifier.Type) -> bool:
	for modifier: Modifier in get_children():
		if modifier.type == type:
			return true
	
	return false

func get_modifier(type: Modifier.Type) -> Modifier:
	for modifier: Modifier in get_children():
		if modifier.type == type:
			return modifier
	
	return null

func get_modified_value(base: int, type: Modifier.Type) -> int:
	var modifier := get_modifier(type)
	
	if not modifier:
		return base
	
	else:
		return modifier.get_modified_value(base)
