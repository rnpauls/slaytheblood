class_name ValueProp
extends RefCounted

## Mutable wrapper passed through modifier hooks so each hook can see
## the running total before deciding its own contribution.

var value: int

func _init(initial: int) -> void:
	value = initial
