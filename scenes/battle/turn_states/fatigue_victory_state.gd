class_name FatigueVictoryState
extends TurnState

const FATIGUE_DAMAGE := 10
const BANNER_OPEN_DELAY := 0.25
const POST_HIT_PAUSE := 0.20


func enter() -> void:
	battle.battle_ui.show_turn_announcement("VICTORY BY FATIGUE")
	_run_beat_up_routine()


func _run_beat_up_routine() -> void:
	await get_tree().create_timer(BANNER_OPEN_DELAY).timeout

	while _alive_enemies_count() > 0:
		var target := _nearest_alive_enemy()
		if target == null:
			return
		await battle.player.jerk_attack(target.global_position)
		for child in enemy_handler.get_children():
			if not (child is Enemy):
				continue
			var e := child as Enemy
			if not is_instance_valid(e) or e.stats == null or e.stats.health <= 0:
				continue
			e.take_damage(FATIGUE_DAMAGE, Modifier.Type.NO_MODIFIER,
				Card.DamageKind.PHYSICAL, -1, true)
		await get_tree().create_timer(POST_HIT_PAUSE).timeout


func _alive_enemies_count() -> int:
	var n := 0
	for child in enemy_handler.get_children():
		if child is Enemy and is_instance_valid(child) \
				and child.stats != null and child.stats.health > 0:
			n += 1
	return n


func _nearest_alive_enemy() -> Enemy:
	var best: Enemy = null
	var best_d := INF
	var origin := battle.player.global_position
	for child in enemy_handler.get_children():
		if not (child is Enemy):
			continue
		var e := child as Enemy
		if not is_instance_valid(e) or e.stats == null or e.stats.health <= 0:
			continue
		var d := origin.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
