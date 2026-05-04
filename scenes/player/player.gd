class_name Player
extends Combatant

## Cards that cannot be used to block this turn due to Intimidate. Set by IntimidatedStatus.
var intimidated_cards: Array[Card] = []

func _on_stats_set() -> void:
	if not is_inside_tree():
		await ready
	sprite_2d.texture = stats.art
	update_stats()

func _on_death() -> void:
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
