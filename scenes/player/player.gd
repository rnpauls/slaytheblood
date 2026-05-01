class_name Player
extends Combatant

func _on_stats_set() -> void:
	if not is_inside_tree():
		await ready
	sprite_2d.texture = stats.art
	update_stats()

func _on_death() -> void:
	Events.player_died.emit()
	queue_free()
