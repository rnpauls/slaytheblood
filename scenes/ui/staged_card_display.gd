## Receives an EnemyCardUI from Events.attack_card_staged, reparents it to this
## Control (which lives on the BattleUI CanvasLayer), positions it at a fixed
## screen location, and allows hover-to-zoom in place.
class_name StagedCardDisplay
extends Control

## Scale while staged (resting, not hovered).
@export var staged_scale  := 0.5
## Scale when hovered. 0.6 is the card's natural full display size.
@export var hovered_scale := 1.0

var _card_ui: EnemyCardUI = null
var _original_parent: Node = null
var _original_position: Vector2 = Vector2.ZERO
var _original_scale: Vector2 = Vector2.ZERO
var _original_rotation: float = 0.0
var _is_hovered := false

func _ready() -> void:
	Events.attack_card_staged.connect(_on_attack_card_staged)
	Events.attack_card_unstaged.connect(_on_attack_card_unstaged)
	# This container itself should not eat mouse events
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# ── Stage / unstage ───────────────────────────────────────────────────────────

func _on_attack_card_staged(card_ui: EnemyCardUI) -> void:
	if is_instance_valid(_card_ui):
		_return_card()

	_card_ui = card_ui
	_original_parent   = card_ui.get_parent()
	# Save global_position because EnemyHand positions cards via global_position
	# (not local position), so restoring local position would place the card wrong.
	_original_position = card_ui.global_position
	_original_scale    = card_ui.scale
	_original_rotation = card_ui.rotation_degrees

	# Reparent to this Control so it draws above everything else
	card_ui.reparent(self)
	card_ui.z_index = 20

	# Connect hover for in-place zoom
	if not card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.connect(_on_card_hovered)
	if not card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.connect(_on_card_unhovered)

	# We want the card visually centered on this node's center in screen space.
	# This node is anchored to screen center in battle.tscn (offset ±100, -200..0),
	# so its center in local space is (size.x/2, size.y/2).
	# card pivot_offset = (100,140), so: position = center - pivot * staged_scale
	# We use get_rect().get_center() which works even if size is zero by using
	# the node's own rect in parent space. Instead, just use (0,0) as our local
	# center and let the anchor in battle.tscn do the screen positioning.
	# Cards position in StagedCardDisplay local space; (0,0) = node's top-left.
	# The node is 200x200 (offsets -100..100, -200..0 = 200x200),
	# so center in local space = (100, 100).
	var local_center := Vector2(100.0, 100.0)
	var target_pos := local_center - Vector2(100.0, 140.0) * staged_scale

	var t := card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card_ui, "position", target_pos, 0.3)
	t.parallel().tween_property(card_ui, "scale", Vector2.ONE * staged_scale, 0.3)
	t.parallel().tween_property(card_ui, "rotation_degrees", 0.0, 0.3)

func _on_attack_card_unstaged() -> void:
	_return_card()

func _return_card() -> void:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return

	var card_ui := _card_ui
	_card_ui = null
	_is_hovered = false

	if card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.disconnect(_on_card_hovered)
	if card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.disconnect(_on_card_unhovered)

	if is_instance_valid(_original_parent) and is_instance_valid(card_ui):
		card_ui.reparent(_original_parent)
		card_ui.z_index = 0
		var t := card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t.tween_property(card_ui, "global_position", _original_position, 0.2)
		t.parallel().tween_property(card_ui, "scale", _original_scale, 0.2)
		t.parallel().tween_property(card_ui, "rotation_degrees", _original_rotation, 0.2)
	elif is_instance_valid(card_ui):
		card_ui.queue_free()

# ── Hover zoom (scale only — pivot_offset handles the anchor, no pos change) ──

func _on_card_hovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or _is_hovered:
		return
	_is_hovered = true

	# Only tween scale. pivot_offset=(100,140) on the card means Godot scales
	# around the card center automatically — no position adjustment needed.
	var t := _card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_card_ui, "scale", Vector2.ONE * hovered_scale, 0.15)
	#t.parallel().tween_property(_card_ui, "rotation_degrees", 0.0, 0.15)

func _on_card_unhovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or not _is_hovered:
		return
	_is_hovered = false

	# Only tween scale back — pivot_offset keeps the center stable.
	var t := _card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(_card_ui, "scale", Vector2.ONE * staged_scale, 0.15)
