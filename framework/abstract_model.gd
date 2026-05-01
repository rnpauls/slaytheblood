class_name AbstractModel
extends Resource

## Base class for every Hook-registered game entity (statuses, relics, card effects).
## Subclasses override only the hook methods they care about.
##
## Owner lifecycle: _owner_ref is a WeakRef so holding an AbstractModel never
## prevents a combat Node from being freed. Always call owner() and null-check.

signal model_changed

# Set by Hook.register(). Use owner() to access safely.
var _owner_ref: WeakRef

# Set by Hook when register() is called mid-dispatch, so hooks can skip the
# card that triggered their registration (see _skip_play_key pattern).
var _registered_during_play_key: String = ""


func owner() -> Node:
	if _owner_ref == null:
		return null
	return _owner_ref.get_ref() as Node


# --- Visibility ---

## Return true for models that should appear in the status bar UI.
func visible_in_ui() -> bool:
	return false

## Short string shown in the status icon (stacks, duration, etc.).
## Only called when visible_in_ui() is true.
func ui_stack_text() -> String:
	return ""

## Icon texture for the status bar. Only called when visible_in_ui() is true.
func ui_icon() -> Texture2D:
	return null

## Tooltip text shown on hover.
func ui_tooltip() -> String:
	return ""


# --- Damage / block modification (return value is composed by Hook) ---

func modify_damage_additive(_dealer: Node, _target: Node, _vp: ValueProp) -> int:
	return 0

func modify_damage_multiplicative(_dealer: Node, _target: Node, _vp: ValueProp) -> float:
	return 1.0

func modify_block_additive(_owner_node: Node, _vp: ValueProp) -> int:
	return 0

func modify_block_multiplicative(_owner_node: Node, _vp: ValueProp) -> float:
	return 1.0


# --- Lifecycle (side effects only, no return value) ---

func before_card_played(_card: Card, _ctx: Dictionary) -> void:
	pass

func after_card_played(_card: Card, _ctx: Dictionary) -> void:
	pass

func after_turn_end(_side: String) -> void:
	pass

func after_attack_completed(_attacker: Node, _ctx: Dictionary) -> void:
	pass

func on_hit_dealt(_dealer: Node, _target: Node, _ctx: Dictionary) -> void:
	pass

func on_hit_received(_dealer: Node, _target: Node, _ctx: Dictionary) -> void:
	pass
