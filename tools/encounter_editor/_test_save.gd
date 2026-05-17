## Headless smoke test for encounter saving. Run with:
##   Godot --headless --path . res://tools/encounter_editor/_test_save.tscn
## Runs as a scene so project autoloads (RNG, etc.) load before BattleStats
## scripts get compiled.
extends Node


func _ready() -> void:
	var editor_scene: PackedScene = load("res://tools/encounter_editor/encounter_editor.tscn")
	var editor: Control = editor_scene.instantiate()
	add_child(editor)
	# Wait one frame so @onready resolves.
	await get_tree().process_frame
	await get_tree().process_frame

	print("=== ENCOUNTER EDITOR SMOKE TEST ===")
	print("Battles scanned: %d" % editor._battle_paths.size())
	print("Enemies scanned: %d" % editor._enemy_paths.size())

	# Pick the first enemy and stage a fake encounter.
	if editor._enemy_paths.is_empty():
		push_error("No enemies found — aborting test.")
		get_tree().quit(1)
		return
	var sample_enemy: String = editor._enemy_paths[0]
	editor._add_token(sample_enemy, Vector2(700, 300))
	editor._add_token(sample_enemy, Vector2(900, 300))

	editor.tier_spin.value = 0
	editor.weight_spin.value = 0.5
	editor.gold_min_spin.value = 10
	editor.gold_max_spin.value = 20
	editor.name_edit.text = "_smoke_test_battle"

	var test_path := "res://tools/encounter_editor/_smoke_test_battle.tres"
	var test_scene_path := "res://tools/encounter_editor/_smoke_test_battle.tscn"
	editor._save_to(test_path)

	# Load it back and verify.
	var battle: BattleStats = load(test_path)
	if battle == null:
		push_error("Saved .tres did not load.")
		get_tree().quit(1)
		return
	print("Loaded battle — tier=%d weight=%s gold=%d-%d enemies=%s" % [
		battle.battle_tier, battle.weight, battle.gold_reward_min,
		battle.gold_reward_max, str(battle.enemies)
	])

	if battle.enemies == null:
		push_error("Battle.enemies not set.")
		get_tree().quit(1)
		return

	var scene_root: Node = battle.enemies.instantiate()
	print("Battle scene root: %s, children: %d" % [scene_root.name, scene_root.get_child_count()])
	for child in scene_root.get_children():
		print("  - %s @ %s, stats=%s" % [
			child.name, str(child.position), str(child.get("stats"))
		])
	scene_root.free()

	# Clean up so the test artefacts don't pollute the project.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_scene_path))

	# Also verify we can load an existing battle and surface its enemy tokens.
	editor._on_new_pressed()
	editor._load_battle("res://encounters/tier_1_bat_crab.tres")
	if editor._tokens.size() != 2:
		push_error("Expected 2 tokens after loading tier_1_bat_crab, got %d" % editor._tokens.size())
		get_tree().quit(1)
		return
	for t in editor._tokens:
		print("  loaded token: stats=%s center=%s" % [t.get_meta("stats_path"), t.get_meta("center")])

	print("=== TEST OK ===")
	get_tree().quit(0)
