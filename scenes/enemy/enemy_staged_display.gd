## Per-enemy staged card display.
## The card is reparented into this node (a Control) when staged, so that
## position arithmetic is consistent — Control-in-Control has no coordinate
## space mismatch between position and global_position.
##
## StagedDisplay should be placed in the scene at the pixel where you want the
## card's top-left corner to land.  The card animates to position=(0,0) local,
## i.e. its top-left aligns with this node's top-left.
class_name EnemyStagedDisplay
extends Node2D

@export var staged_scale  := 0.55
@export var hovered_scale := 1.0

var _card_ui: EnemyCardUI       = null
var _original_parent: Node      = null
var _is_hovered                 := false

# ── Public API ────────────────────────────────────────────────────────────────

func stage(card_ui: EnemyCardUI) -> void:
	if is_instance_valid(_card_ui):
		_return_instant()

	_card_ui         = card_ui
	_original_parent = card_ui.get_parent()

	card_ui.reparent(self)
	card_ui.z_index      = 0
	card_ui.z_as_relative = true

	if not card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.connect(_on_card_hovered)
	if not card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.connect(_on_card_unhovered)

	# Animate to top-left of this Control (position 0,0 in local space).
	card_ui.animate_to_local_position_and_rotation_and_scale(Vector2.ZERO, 0.0, staged_scale, 0.3)

func unstage() -> void:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return
	_disconnect_hover(_card_ui)
	var card_ui  := _card_ui
	_card_ui     = null
	_is_hovered  = false
	_return_to_hand(card_ui)

func release() -> EnemyCardUI:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return null
	_disconnect_hover(_card_ui)
	var card_ui  := _card_ui
	_card_ui     = null
	_is_hovered  = false
	card_ui.reparent(_original_parent)
	return card_ui

# ── Private ───────────────────────────────────────────────────────────────────

func _return_to_hand(card_ui: EnemyCardUI) -> void:
	if is_instance_valid(_original_parent):
		card_ui.reparent(_original_parent)
		if _original_parent is EnemyHand:
			(_original_parent as EnemyHand)._arrange_cards()
	else:
		card_ui.queue_free()

func _return_instant() -> void:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return
	_disconnect_hover(_card_ui)
	var card_ui  := _card_ui
	_card_ui     = null
	_is_hovered  = false
	_return_to_hand(card_ui)

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
	# Scale up around top-left — position stays at (0,0).
	_card_ui.animate_to_local_position_and_rotation_and_scale(Vector2.ZERO, 0.0, hovered_scale, 0.25)

func _on_card_unhovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or not _is_hovered:
		return
	_is_hovered = false
	_card_ui.animate_to_local_position_and_rotation_and_scale(Vector2.ZERO, 0.0, staged_scale, 0.25)
