class_name ModifierValue
extends Node

enum Type {PERCENT_BASED, FLAT}

@export var type: Type
@export var percent_value: float
@export var flat_value: int
@export var source: String
## When true, this value is skipped unless the resolving call passes
## damage_kind == PHYSICAL. Lets a status (e.g. Wraith Phase) reduce only
## physical damage taken, leaving arcane untouched. Default false preserves
## existing behavior for every modifier value already in the codebase.
@export var only_physical: bool = false

static func create_new_modifier(modifier_source: String, what_type: Type) -> ModifierValue:
	var new_modifier := new()
	new_modifier.source = modifier_source
	new_modifier.type = what_type

	return new_modifier
