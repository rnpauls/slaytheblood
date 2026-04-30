## Per-enemy staged card display.
## When an enemy declares an attack the attack card is reparented here and
## animated into a fixed position above the enemy sprite so the player can see
## exactly which enemy is attacking.  Hovering the card zooms it in-place.
class_name EnemyStagedDisplay
extends Node2D

## Scale while at rest in the staged position.
@export var staged_scale  := 0.55
## Scale when hovered (full natural display scale).
@export var hovered_scale := 1.0

var _card_ui: EnemyCardUI       = null
var _original_parent: Node      = null
var _original_position: Vector2 = Vector2.ZERO
var _original_scale: Vector2    = Vector2.ZERO
var _original_rotation: float   = 0.0
var _is_hovered := false

# ── Public API ────────────────────────────────────────────────────────────────

## Animate card_ui into the staged position above this enemy.
## Saves the card's original parent/position/scale so it can be returned later.
func stage(card_ui: EnemyCardUI) -> void:
	if is_instance_valid(_card_ui):
		_return_card_instant()

	_card_ui           = card_ui
	_original_parent   = card_ui.get_parent()
	_original_position = card_ui.position
	_original_scale    = card_ui.scale
	_original_rotation = card_ui.rotation_degrees

	card_ui.reparent(self)
	# Use absolute z so the staged card renders above all enemies in the scene.
	card_ui.z_index = 20
	if card_ui is CanvasItem:
		(card_ui as CanvasItem).z_as_relative = false

	# Connect hover for in-place zoom
	if not card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.connect(_on_card_hovered)
	if not card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.connect(_on_card_unhovered)

	# Target position: card top-center at (0,0) in this node's local space.
	# pivot_offset = (100, 140) on CardUI, so card top-left = (-100*scale, -140*scale)
	# to have the visual center land at (0,0).
	var target_pos := Vector2(-100.0, -140.0) * staged_scale

	var t := card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card_ui, "position",         target_pos,              0.3)
	t.parallel().tween_property(card_ui, "scale", Vector2.ONE * staged_scale, 0.3)
	t.parallel().tween_property(card_ui, "rotation_degrees", 0.0,          0.3)

## Animate the card back to where it came from and clean up.
func unstage() -> void:
	_return_card()

## Release the card without animating it back — caller takes ownership for play/block.
## Returns the EnemyCardUI so the caller can reparent/use it directly.
func release() -> EnemyCardUI:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return null
	var card_ui := _card_ui
	_card_ui    = null
	_is_hovered = false
	_disconnect_hover(card_ui)
	# Reparent back to original parent so play() animation has a valid context.
	if is_instance_valid(_original_parent):
		card_ui.reparent(_original_parent)
	card_ui.z_index = 0
	if card_ui is CanvasItem:
		(card_ui as CanvasItem).z_as_relative = true
	return card_ui

# ── Private ───────────────────────────────────────────────────────────────────

func _return_card() -> void:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return

	var card_ui := _card_ui
	_card_ui    = null
	_is_hovered = false
	_disconnect_hover(card_ui)

	if is_instance_valid(_original_parent) and is_instance_valid(card_ui):
		card_ui.reparent(_original_parent)
		card_ui.z_index = 0
		if card_ui is CanvasItem:
			(card_ui as CanvasItem).z_as_relative = true
		var t := card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t.tween_property(card_ui, "position",         _original_position, 0.2)
		t.parallel().tween_property(card_ui, "scale", _original_scale,    0.2)
		t.parallel().tween_property(card_ui, "rotation_degrees", _original_rotation, 0.2)
	elif is_instance_valid(card_ui):
		card_ui.queue_free()

func _return_card_instant() -> void:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return
	var card_ui := _card_ui
	_card_ui    = null
	_is_hovered = false
	_disconnect_hover(card_ui)
	if is_instance_valid(_original_parent) and is_instance_valid(card_ui):
		card_ui.reparent(_original_parent)
		card_ui.z_index = 0
		if card_ui is CanvasItem:
			(card_ui as CanvasItem).z_as_relative = true
		card_ui.position         = _original_position
		card_ui.scale            = _original_scale
		card_ui.rotation_degrees = _original_rotation
	elif is_instance_valid(card_ui):
		card_ui.queue_free()

func _disconnect_hover(card_ui: EnemyCardUI) -> void:
	if card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.disconnect(_on_card_hovered)
	if card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.disconnect(_on_card_unhovered)

# ── Hover zoom ────────────────────────────────────────────────────────────────

func _on_card_hovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or _is_hovered:
		return
	_is_hovered = true
	var t := _card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_card_ui, "scale", Vector2.ONE * hovered_scale, 0.15)
	t.parallel().tween_property(_card_ui, "rotation_degrees", 0.0, 0.15)

func _on_card_unhovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or not _is_hovered:
		return
	_is_hovered = false
	var t := _card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(_card_ui, "scale", Vector2.ONE * staged_scale, 0.15)
