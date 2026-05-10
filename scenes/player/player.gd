class_name Player
extends Combatant

const LEGACY_SPRITE_HALF_EXTENT := 60.0

## Cards that cannot be used to block this turn due to Intimidate. Set by IntimidatedStatus.
var intimidated_cards: Array[Card] = []

## Back-reference to the PlayerHandler that owns this player. Set by
## PlayerHandler.start_battle. Lets effects / relics that need the handler
## reach it via combatant.player_handler instead of a scene-tree group lookup.
var player_handler: PlayerHandler

@onready var mouse_hover_collision: CollisionShape2D = $MouseHoverArea/CollisionShape2D

@onready var _stats_origin_y: float = stats_ui.position.y
@onready var _status_origin_y: float = status_handler.position.y


## Mirror of Enemy.add_card_to_hand: add a Card to the player's hand,
## skipping the draw pile. Used by CardAddEffect when destination is HAND so
## effects don't have to branch on `target is Player` vs `target is Enemy`.
func add_card_to_hand(card: Card) -> void:
	if player_handler == null or player_handler.hand == null:
		return
	player_handler.hand.add_card(card)

func _on_stats_set() -> void:
	if not is_inside_tree():
		await ready
	sprite_2d.texture = stats.art
	var s : float = stats.display_height / stats.art.get_height()
	sprite_2d.scale = Vector2(s, s)

	var half := sprite_2d.get_rect().size * sprite_2d.scale * 0.5
	var dy := half.y - LEGACY_SPRITE_HALF_EXTENT

	stats_ui.position.y = _stats_origin_y + dy
	status_handler.position.y = _status_origin_y + dy
	(mouse_hover_collision.shape as RectangleShape2D).size = half * 2.0

	update_stats()

func _on_death() -> void:
	# queue_free skips mouse_exited on our hover sources (StatusHandler, sprite
	# hover area), so a tooltip shown for the player would otherwise stay on screen.
	Events.tooltip_hide_requested.emit()
	Events.player_died.emit()
	queue_free()


func _on_mouse_hover_entered() -> void:
	var sh := get_node_or_null("StatusHandler") as StatusHandler
	if sh == null:
		return
	var entries := sh.get_tooltip_entries()
	if entries.is_empty():
		return
	# Anchor to the sprite's canvas-space rect so the tooltip sits beside the
	# player. get_global_transform_with_canvas folds in any camera/zoom so the
	# rect lands in the same coordinate system the TooltipLayer uses.
	var rect := sprite_2d.get_global_transform_with_canvas() * sprite_2d.get_rect()
	Events.tooltip_show_requested.emit(entries, rect)


func _on_mouse_hover_exited() -> void:
	Events.tooltip_hide_requested.emit()
