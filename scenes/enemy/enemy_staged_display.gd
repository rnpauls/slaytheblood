## Per-enemy staged card display.
## Animates the attack card into a prominent position above the enemy sprite so
## the player can see which card is being played.  The card stays a child of
## EnemyHand the entire time — we only tween its position/scale/z_index.
##
## All movement delegates to CardUI.animate_to_global_position_and_rotation_and_scale()
## which uses self.create_tween() on the card — the only reliable way to tween
## global_position on a Control that is a child of a Node2D.
class_name EnemyStagedDisplay
extends Node2D

## Scale while at rest in the staged position.
@export var staged_scale  := 0.55
## Scale when hovered (full natural display scale).
@export var hovered_scale := 1.0

var _card_ui: EnemyCardUI  = null
var _is_hovered            := false
var _staged_rest_gpos      := Vector2.ZERO

# ── Public API ────────────────────────────────────────────────────────────────

func stage(card_ui: EnemyCardUI) -> void:
	if is_instance_valid(_card_ui):
		_clear_staged()

	_card_ui = card_ui

	card_ui.z_index = 20
	if card_ui is CanvasItem:
		(card_ui as CanvasItem).z_as_relative = false

	# Disconnect from EnemyHand's hover callbacks so _arrange_cards() doesn't
	# fight the staged tween when the player mouses over the card.
	var hand := card_ui.get_parent()
	if hand is EnemyHand:
		var eh := hand as EnemyHand
		if card_ui.card_hovered.is_connected(eh._on_card_hovered):
			card_ui.card_hovered.disconnect(eh._on_card_hovered)
		if card_ui.card_unhovered.is_connected(eh._on_card_unhovered):
			card_ui.card_unhovered.disconnect(eh._on_card_unhovered)

	if not card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.connect(_on_card_hovered)
	if not card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.connect(_on_card_unhovered)

	# Bottom-center of card (pivot at 100,140 with scale) lands at this node's global origin.
	_staged_rest_gpos = global_position + Vector2(-100.0, -280.0) * staged_scale

	card_ui.animate_to_global_position_and_rotation_and_scale(_staged_rest_gpos, 0.0, staged_scale, 0.3)

func unstage() -> void:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return
	var card_ui := _card_ui
	_card_ui    = null
	_is_hovered = false
	_disconnect_hover(card_ui)
	card_ui.z_index = 0
	if card_ui is CanvasItem:
		(card_ui as CanvasItem).z_as_relative = true
	var hand := card_ui.get_parent()
	if hand is EnemyHand:
		var eh := hand as EnemyHand
		_reconnect_to_hand(card_ui, eh)
		eh._arrange_cards()

func release() -> EnemyCardUI:
	if not is_instance_valid(_card_ui):
		_card_ui = null
		return null
	var card_ui := _card_ui
	_card_ui    = null
	_is_hovered = false
	_disconnect_hover(card_ui)
	card_ui.z_index = 0
	if card_ui is CanvasItem:
		(card_ui as CanvasItem).z_as_relative = true
	var hand := card_ui.get_parent()
	if hand is EnemyHand:
		_reconnect_to_hand(card_ui, hand as EnemyHand)
	return card_ui

# ── Private ───────────────────────────────────────────────────────────────────

func _clear_staged() -> void:
	if is_instance_valid(_card_ui):
		_disconnect_hover(_card_ui)
		_card_ui.z_index = 0
		if _card_ui is CanvasItem:
			(_card_ui as CanvasItem).z_as_relative = true
		var hand := _card_ui.get_parent()
		if hand is EnemyHand:
			_reconnect_to_hand(_card_ui, hand as EnemyHand)
	_card_ui    = null
	_is_hovered = false

func _disconnect_hover(card_ui: EnemyCardUI) -> void:
	if card_ui.card_hovered.is_connected(_on_card_hovered):
		card_ui.card_hovered.disconnect(_on_card_hovered)
	if card_ui.card_unhovered.is_connected(_on_card_unhovered):
		card_ui.card_unhovered.disconnect(_on_card_unhovered)

func _reconnect_to_hand(card_ui: EnemyCardUI, hand: EnemyHand) -> void:
	if not card_ui.card_hovered.is_connected(hand._on_card_hovered):
		card_ui.card_hovered.connect(hand._on_card_hovered)
	if not card_ui.card_unhovered.is_connected(hand._on_card_unhovered):
		card_ui.card_unhovered.connect(hand._on_card_unhovered)

# ── Hover zoom ────────────────────────────────────────────────────────────────

func _on_card_hovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or _is_hovered:
		return
	_is_hovered = true

	var top_edge_at_hovered := global_position.y - 280.0 * hovered_scale
	var offset_y := maxf(0.0, float(Constants.TOP_BAR_HEIGHT) - top_edge_at_hovered)
	var target_gpos := Vector2(global_position.x - 100.0 * hovered_scale,
							   global_position.y - 280.0 * hovered_scale + offset_y)

	_card_ui.animate_to_global_position_and_rotation_and_scale(target_gpos, 0.0, hovered_scale, 0.25)

func _on_card_unhovered(_card: EnemyCardUI) -> void:
	if not is_instance_valid(_card_ui) or not _is_hovered:
		return
	_is_hovered = false
	_card_ui.animate_to_global_position_and_rotation_and_scale(_staged_rest_gpos, 0.0, staged_scale, 0.25)
