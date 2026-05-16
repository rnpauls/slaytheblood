## Per-enemy staged card display.
## The card (a Control) is reparented into this Node2D when staged.
##
## StagedDisplay should be placed in the scene at the pixel where you want the
## card's visible *center* to land.  CardUI has pivot_offset = (100,140) — the
## center of its 200×280 rect — so Control scaling happens around the pivot.
## To keep the visible center anchored at our origin across scale changes, we
## animate `position` to -pivot_offset (a constant), which places the pivot at
## (0,0) regardless of scale.  This makes hover zoom grow symmetrically about
## the staged position instead of expanding toward the bottom-right.
##
## When hovering at a higher scale, the card's visible top edge could rise
## above the TopBar.  _scale_target() pushes the card down just enough to keep
## its top edge at or below Constants.TOP_BAR_HEIGHT in screen space.
class_name EnemyStagedDisplay
extends Node2D

## Must match CardUI.tscn's pivot_offset.  If that scene changes, update here.
const CARD_PIVOT_OFFSET := Vector2(100, 140)

@export var staged_scale  := 0.55
@export var hovered_scale := 1.0

var _card_ui: EnemyCardUI       = null
var _original_parent: Node      = null
var _is_hovered                 := false

## Local-space target for a given scale that pins the card's visible center
## to (0,0) — except when doing so would push the top edge above the TopBar,
## in which case we slide the card down by just enough to clear the bar.
##
## Visible top edge in local y when position.y = -p.y is -p.y * s.
## In global y that's staged_display.global_position.y - p.y * s.
## We need that >= TOP_BAR_HEIGHT, otherwise add the shortfall to local y.
func _scale_target(s: float) -> Vector2:
	var top_edge_global_y := global_position.y - CARD_PIVOT_OFFSET.y * s
	var clamp_push        := maxf(0.0, Constants.TOP_BAR_HEIGHT - top_edge_global_y)
	return Vector2(-CARD_PIVOT_OFFSET.x, -CARD_PIVOT_OFFSET.y + clamp_push)

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

	# Animate so the card's visible center aligns with this node's origin
	# (clamped so the top edge never goes past the TopBar).
	card_ui.animate_to_local_position_and_rotation_and_scale(
		_scale_target(staged_scale), 0.0, staged_scale, Constants.TWEEN_CARD_STAGE
	)

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

## Like release() but does NOT reparent — caller takes the card_ui in place,
## leaving it parented to this StagedDisplay. Used for NAAs that should fade
## out from the staged position without flashing back to the hand.
func clear_staged() -> EnemyCardUI:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return null
	_disconnect_hover(_card_ui)
	var card_ui  := _card_ui
	_card_ui     = null
	_is_hovered  = false
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
	# Center stays pinned; scaling expands symmetrically around it,
	# but clamp so the card's top edge doesn't slide under the TopBar.
	_card_ui.animate_to_local_position_and_rotation_and_scale(
		_scale_target(hovered_scale), 0.0, hovered_scale, Constants.TWEEN_FADE
	)
	_card_ui.request_tooltip()

func _on_card_unhovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or not _is_hovered:
		return
	_is_hovered = false
	_card_ui.animate_to_local_position_and_rotation_and_scale(
		_scale_target(staged_scale), 0.0, staged_scale, Constants.TWEEN_FADE
	)
	Events.tooltip_hide_requested.emit()
