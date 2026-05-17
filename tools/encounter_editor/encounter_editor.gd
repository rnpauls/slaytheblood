## Encounter editor — design new combat encounters visually.
##
## Open this scene in the editor and run it (F6). Create or load a battle,
## drag enemy tokens to position them on the 1280×720 game canvas, edit the
## BattleStats fields (tier, weight, gold), and save. Optionally register the
## battle into battle_stats_pool.tres so it shows up in runs.
##
## Saved files:
##   res://encounters/<name>.tres  — BattleStats resource (via ResourceSaver)
##   res://encounters/<name>.tscn  — Node2D scene with Enemy children at positions
extends Control

const ENCOUNTERS_DIR := "res://encounters/"
const ENEMIES_DIR := "res://enemies/"
const BATTLE_POOL_PATH := "res://encounters/battle_stats_pool.tres"
const ENEMY_SCENE_PATH := "res://scenes/enemy/enemy.tscn"

const TOKEN_SIZE := Vector2(96, 96)
const CANVAS_W := 1280
const CANVAS_H := 720
## The canvas displays the 1280×720 game viewport scaled to fit between the
## side panels. Token center coords stay in game-space; only the Control's
## visual size and position get scaled.
const DISPLAY_SCALE := 0.6
const TOKEN_DISPLAY_SIZE := TOKEN_SIZE * DISPLAY_SCALE
const SELECTED_BORDER := Color(1, 0.85, 0.2, 1)

@onready var battle_list: ItemList = $LeftPanel/VBox/BattleList
@onready var enemy_list: ItemList = $RightPanel/VBox/EnemyList
@onready var enemy_filter: LineEdit = $RightPanel/VBox/Filter
@onready var canvas: Control = $Canvas
@onready var canvas_hint: Label = $Canvas/Hint

@onready var name_edit: LineEdit = $TopBar/HBox/NameEdit
@onready var tier_spin: SpinBox = $TopBar/HBox/TierSpin
@onready var weight_spin: SpinBox = $TopBar/HBox/WeightSpin
@onready var gold_min_spin: SpinBox = $TopBar/HBox/GoldMinSpin
@onready var gold_max_spin: SpinBox = $TopBar/HBox/GoldMaxSpin
@onready var pool_check: CheckBox = $TopBar/HBox/PoolCheck
@onready var elite_check: CheckBox = $TopBar/HBox/EliteCheck

@onready var pos_x_spin: SpinBox = $RightPanel/VBox/SelectedRow/PosX
@onready var pos_y_spin: SpinBox = $RightPanel/VBox/SelectedRow/PosY
@onready var remove_btn: Button = $RightPanel/VBox/RemoveBtn

@onready var status_label: Label = $BottomBar/StatusLabel

var _battle_paths: Array[String] = []
var _enemy_paths: Array[String] = []
var _enemy_stats_cache: Dictionary = {}

var _current_battle_path: String = ""
var _tokens: Array[Control] = []
var _selected_token: Control = null

## When a drag is in progress, holds the token being dragged. _drag_offset is
## the offset from the token's center to the original click point — used so
## the click point stays under the mouse during drag.
var _drag_token: Control = null
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	get_window().title = "Encounter Editor"
	_scan_battles()
	_scan_enemies()
	_apply_enemy_filter("")

	battle_list.item_selected.connect(_on_battle_selected)
	enemy_list.item_activated.connect(_on_enemy_activated)
	enemy_filter.text_changed.connect(_apply_enemy_filter)

	$LeftPanel/VBox/NewBtn.pressed.connect(_on_new_pressed)
	$LeftPanel/VBox/SaveBtn.pressed.connect(_on_save_pressed)
	$LeftPanel/VBox/SaveAsBtn.pressed.connect(_on_save_as_pressed)
	$LeftPanel/VBox/RefreshBtn.pressed.connect(_refresh_lists)

	$RightPanel/VBox/AddBtn.pressed.connect(_on_add_enemy_pressed)
	remove_btn.pressed.connect(_on_remove_token_pressed)

	pos_x_spin.value_changed.connect(_on_pos_x_changed)
	pos_y_spin.value_changed.connect(_on_pos_y_changed)

	canvas.gui_input.connect(_on_canvas_gui_input)

	_clear_selection()
	_set_status("Ready. Pick a battle from the left, or click 'New'.")


# ── Scanning ─────────────────────────────────────────────────────────────────

func _scan_battles() -> void:
	_battle_paths.clear()
	battle_list.clear()
	_collect_resources(ENCOUNTERS_DIR, _battle_paths, _is_battle_stats)
	_battle_paths.sort()
	for p in _battle_paths:
		battle_list.add_item(p.trim_prefix(ENCOUNTERS_DIR))


func _scan_enemies() -> void:
	_enemy_paths.clear()
	_enemy_stats_cache.clear()
	_collect_resources(ENEMIES_DIR, _enemy_paths, _is_enemy_stats)
	_enemy_paths.sort()
	for p in _enemy_paths:
		_enemy_stats_cache[p] = load(p)


func _refresh_lists() -> void:
	_scan_battles()
	_scan_enemies()
	_apply_enemy_filter(enemy_filter.text)
	_set_status("Refreshed.")


func _collect_resources(root: String, out: Array[String], filter: Callable) -> void:
	var stack: Array[String] = [root]
	while not stack.is_empty():
		var dir_path: String = stack.pop_back()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if entry.begins_with("."):
				entry = dir.get_next()
				continue
			var full := dir_path.path_join(entry)
			if dir.current_is_dir():
				stack.append(full)
			elif entry.ends_with(".tres") and filter.call(full):
				out.append(full)
			entry = dir.get_next()
		dir.list_dir_end()


func _is_battle_stats(path: String) -> bool:
	if path == BATTLE_POOL_PATH:
		return false
	var res := load(path)
	return res is BattleStats


func _is_enemy_stats(path: String) -> bool:
	var res := load(path)
	return res is EnemyStats


# ── Enemy filter ─────────────────────────────────────────────────────────────

func _apply_enemy_filter(text: String) -> void:
	enemy_list.clear()
	var needle := text.to_lower()
	for p in _enemy_paths:
		var stats: EnemyStats = _enemy_stats_cache[p]
		var label := "%s  (%s)" % [stats.character_name, p.trim_prefix(ENEMIES_DIR)]
		if needle == "" or label.to_lower().contains(needle):
			var idx := enemy_list.add_item(label)
			if stats.art:
				enemy_list.set_item_icon(idx, stats.art)
			enemy_list.set_item_metadata(idx, p)


# ── Battle load ──────────────────────────────────────────────────────────────

func _on_battle_selected(idx: int) -> void:
	var path := _battle_paths[idx]
	_load_battle(path)


func _load_battle(path: String) -> void:
	var battle: BattleStats = load(path)
	if battle == null:
		_set_status("Failed to load %s" % path)
		return
	_current_battle_path = path
	name_edit.text = path.get_file().get_basename()
	tier_spin.value = battle.battle_tier
	weight_spin.value = battle.weight
	gold_min_spin.value = battle.gold_reward_min
	gold_max_spin.value = battle.gold_reward_max

	_clear_tokens()
	_clear_selection()

	if battle.enemies == null:
		_set_status("Loaded %s — no enemies scene attached." % path.get_file())
		return

	# Read the scene's stored properties directly via SceneState rather than
	# instantiating. The Enemy script's stats setter calls create_instance()
	# which duplicate()'s the resource — the duplicate has an empty
	# resource_path, so instantiating would lose the link to the original
	# .tres file we want to track.
	var packed: PackedScene = battle.enemies
	var state := packed.get_state()
	for node_idx in state.get_node_count():
		var node_path := state.get_node_path(node_idx)
		# Skip the root (NodePath ".").
		if node_path == NodePath("."):
			continue
		var pos := Vector2.ZERO
		var stats_path := ""
		for prop_idx in state.get_node_property_count(node_idx):
			var prop_name := state.get_node_property_name(node_idx, prop_idx)
			var prop_val: Variant = state.get_node_property_value(node_idx, prop_idx)
			if prop_name == "position":
				pos = prop_val
			elif prop_name == "stats" and prop_val is Resource:
				stats_path = (prop_val as Resource).resource_path
		if stats_path != "":
			_add_token(stats_path, pos)
	_set_status("Loaded %s — %d enemies." % [path.get_file(), _tokens.size()])


# ── Token management ─────────────────────────────────────────────────────────

func _add_token(stats_path: String, pos: Vector2) -> Control:
	var stats: EnemyStats = _enemy_stats_cache.get(stats_path)
	if stats == null:
		stats = load(stats_path)
		if stats == null:
			_set_status("Could not load %s" % stats_path)
			return null
		_enemy_stats_cache[stats_path] = stats

	var token := PanelContainer.new()
	token.custom_minimum_size = TOKEN_DISPLAY_SIZE
	token.size = TOKEN_DISPLAY_SIZE
	token.position = pos * DISPLAY_SCALE - TOKEN_DISPLAY_SIZE * 0.5
	token.set_meta("stats_path", stats_path)
	token.set_meta("center", pos)
	token.mouse_filter = Control.MOUSE_FILTER_STOP
	token.tooltip_text = "%s\n%s" % [stats.character_name, stats_path]

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	sb.border_color = Color(0.6, 0.6, 0.65, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	token.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_child(vbox)

	if stats.art:
		var tex := TextureRect.new()
		tex.texture = stats.art
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(36, 36)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(tex)

	var label := Label.new()
	label.text = stats.character_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(label)

	token.gui_input.connect(_on_token_gui_input.bind(token))
	canvas.add_child(token)
	_tokens.append(token)
	canvas_hint.visible = false
	return token


func _select_token(token: Control) -> void:
	if _selected_token == token:
		return
	if _selected_token != null:
		_paint_token_border(_selected_token, Color(0.6, 0.6, 0.65, 1))
	_selected_token = token
	if token != null:
		_paint_token_border(token, SELECTED_BORDER)
		var center: Vector2 = token.get_meta("center")
		pos_x_spin.set_value_no_signal(center.x)
		pos_y_spin.set_value_no_signal(center.y)
		remove_btn.disabled = false
	else:
		remove_btn.disabled = true
		pos_x_spin.set_value_no_signal(0)
		pos_y_spin.set_value_no_signal(0)


func _clear_selection() -> void:
	_select_token(null)


func _paint_token_border(token: Control, color: Color) -> void:
	var sb := token.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = color


func _clear_tokens() -> void:
	for t in _tokens:
		t.queue_free()
	_tokens.clear()
	_selected_token = null
	canvas_hint.visible = true


## `center` is in game-space (0..1280, 0..720). The Control's display position
## is the scaled-down version; the meta + spinboxes stay in game-space.
func _move_token(token: Control, center: Vector2) -> void:
	center.x = clampf(center.x, 0, CANVAS_W)
	center.y = clampf(center.y, 0, CANVAS_H)
	token.set_meta("center", center)
	token.position = center * DISPLAY_SCALE - TOKEN_DISPLAY_SIZE * 0.5
	if token == _selected_token:
		pos_x_spin.set_value_no_signal(center.x)
		pos_y_spin.set_value_no_signal(center.y)


# ── Input ────────────────────────────────────────────────────────────────────

func _on_token_gui_input(event: InputEvent, token: Control) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_select_token(token)
			_drag_token = token
			# _drag_offset is in display pixels (mb.position is local to the
			# scaled-down token). Converted to game-space in _input.
			_drag_offset = mb.position - TOKEN_DISPLAY_SIZE * 0.5
			accept_event()


func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_clear_selection()


# Drag motion + release are tracked at the root level so the mouse can move
# off the token (or even outside the canvas) without losing the drag.
func _input(event: InputEvent) -> void:
	if _drag_token == null:
		return
	if event is InputEventMouseMotion:
		var canvas_pos := canvas.get_local_mouse_position()
		var display_center := canvas_pos - _drag_offset
		_move_token(_drag_token, display_center / DISPLAY_SCALE)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_drag_token = null


# ── Buttons ──────────────────────────────────────────────────────────────────

func _on_new_pressed() -> void:
	_current_battle_path = ""
	name_edit.text = "tier_X_new_battle"
	tier_spin.value = 1
	weight_spin.value = 1.0
	gold_min_spin.value = 30
	gold_max_spin.value = 50
	_clear_tokens()
	_clear_selection()
	battle_list.deselect_all()
	_set_status("New battle. Add enemies and save.")


func _on_enemy_activated(idx: int) -> void:
	_add_enemy_at_default(idx)


func _on_add_enemy_pressed() -> void:
	var sel := enemy_list.get_selected_items()
	if sel.is_empty():
		_set_status("Select an enemy in the right panel first.")
		return
	_add_enemy_at_default(sel[0])


func _add_enemy_at_default(idx: int) -> void:
	var path: String = enemy_list.get_item_metadata(idx)
	# Stagger new enemies so they don't all stack on the same pixel.
	var n := _tokens.size()
	var pos := Vector2(750 + n * 110, 290)
	var token := _add_token(path, pos)
	if token:
		_select_token(token)


func _on_remove_token_pressed() -> void:
	if _selected_token == null:
		return
	_tokens.erase(_selected_token)
	_selected_token.queue_free()
	_selected_token = null
	remove_btn.disabled = true
	if _tokens.is_empty():
		canvas_hint.visible = true


func _on_pos_x_changed(v: float) -> void:
	if _selected_token == null:
		return
	var center: Vector2 = _selected_token.get_meta("center")
	_move_token(_selected_token, Vector2(v, center.y))


func _on_pos_y_changed(v: float) -> void:
	if _selected_token == null:
		return
	var center: Vector2 = _selected_token.get_meta("center")
	_move_token(_selected_token, Vector2(center.x, v))


# ── Save ─────────────────────────────────────────────────────────────────────

func _on_save_pressed() -> void:
	if _current_battle_path == "":
		_on_save_as_pressed()
		return
	_save_to(_current_battle_path)


func _on_save_as_pressed() -> void:
	var basename := name_edit.text.strip_edges()
	if basename == "":
		_set_status("Enter a filename (without extension).")
		return
	if not basename.is_valid_filename():
		# is_valid_filename rejects path separators, but not paths in general.
		# We just want a leaf filename.
		_set_status("Invalid filename.")
		return
	var tres_path := ENCOUNTERS_DIR.path_join(basename + ".tres")
	_save_to(tres_path)


func _save_to(tres_path: String) -> void:
	if _tokens.is_empty():
		_set_status("Add at least one enemy before saving.")
		return
	var basename := tres_path.get_file().get_basename()
	var tscn_path := tres_path.get_basename() + ".tscn"

	var scene_err := _write_battle_scene(tscn_path, basename)
	if scene_err != OK:
		_set_status("Failed to write %s (err %d)" % [tscn_path, scene_err])
		return

	# Force-refresh the resource cache so the freshly written scene is picked
	# up below. ResourceLoader.load() with CACHE_MODE_REPLACE bypasses any
	# cached copy from a previous load of the same path.
	var packed: PackedScene = ResourceLoader.load(
		tscn_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE
	)
	if packed == null:
		_set_status("Wrote scene but could not reload it: %s" % tscn_path)
		return

	var battle: BattleStats
	if ResourceLoader.exists(tres_path):
		battle = ResourceLoader.load(tres_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if battle == null:
		battle = BattleStats.new()

	battle.battle_tier = int(tier_spin.value)
	battle.weight = weight_spin.value
	battle.gold_reward_min = int(gold_min_spin.value)
	battle.gold_reward_max = int(gold_max_spin.value)
	battle.enemies = packed

	var save_err := ResourceSaver.save(battle, tres_path)
	if save_err != OK:
		_set_status("Failed to save %s (err %d)" % [tres_path, save_err])
		return

	_current_battle_path = tres_path

	var pool_msg := ""
	if pool_check.button_pressed:
		pool_msg = " " + _register_in_pool(tres_path, elite_check.button_pressed)

	_refresh_lists()
	_select_battle_in_list(tres_path)
	_set_status("Saved %s.%s" % [tres_path, pool_msg])


func _select_battle_in_list(path: String) -> void:
	var idx := _battle_paths.find(path)
	if idx >= 0:
		battle_list.select(idx)


# Writes the .tscn file in the same hand-edited format that existing battles
# use: a Node2D root, with each enemy as a separate `instance` of enemy.tscn,
# carrying a position and a stats ext_resource. We write text directly so the
# saved file matches the existing style — no transient _ready() children, no
# inspector clutter.
func _write_battle_scene(tscn_path: String, root_name: String) -> int:
	var root_pascal := _to_pascal_case(root_name)
	var enemy_uid_text := _uid_text_for(ENEMY_SCENE_PATH)
	var lines: Array[String] = []
	lines.append('[gd_scene format=3 uid="%s"]' % _new_uid_text())
	lines.append("")
	lines.append('[ext_resource type="PackedScene" uid="%s" path="%s" id="1_enemy"]' % [
		enemy_uid_text, ENEMY_SCENE_PATH
	])

	# Stable per-stats-path id mapping so duplicate enemies share an ext_resource.
	var stats_ids: Dictionary = {}
	var next_id := 2
	for token in _tokens:
		var sp: String = token.get_meta("stats_path")
		if not stats_ids.has(sp):
			stats_ids[sp] = "%d_es" % next_id
			next_id += 1
			lines.append('[ext_resource type="Resource" uid="%s" path="%s" id="%s"]' % [
				_uid_text_for(sp), sp, stats_ids[sp]
			])

	lines.append("")
	lines.append('[node name="%s" type="Node2D"]' % root_pascal)
	lines.append("")

	for i in _tokens.size():
		var token: Control = _tokens[i]
		var sp: String = token.get_meta("stats_path")
		var center: Vector2 = token.get_meta("center")
		var node_name := "Enemy" if i == 0 else "Enemy%d" % (i + 1)
		lines.append('[node name="%s" parent="." instance=ExtResource("1_enemy")]' % node_name)
		lines.append("position = Vector2(%s, %s)" % [_fmt_num(center.x), _fmt_num(center.y)])
		lines.append('stats = ExtResource("%s")' % stats_ids[sp])
		lines.append("")

	var f := FileAccess.open(tscn_path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string("\n".join(lines))
	f.close()
	return OK


func _register_in_pool(tres_path: String, as_elite: bool) -> String:
	var pool: BattleStatsPool = ResourceLoader.load(
		BATTLE_POOL_PATH, "", ResourceLoader.CACHE_MODE_REPLACE
	)
	if pool == null:
		return "Pool registration skipped: could not load pool."

	var battle: BattleStats = ResourceLoader.load(
		tres_path, "", ResourceLoader.CACHE_MODE_REPLACE
	)
	if battle == null:
		return "Pool registration skipped: could not reload battle."

	var target: Array = pool.elite_pool if as_elite else pool.pool
	for existing in target:
		if existing != null and existing.resource_path == tres_path:
			return "Already in %s." % ("elite_pool" if as_elite else "pool")

	target.append(battle)
	var err := ResourceSaver.save(pool, BATTLE_POOL_PATH)
	if err != OK:
		return "Pool save failed (err %d)." % err
	return "Added to %s." % ("elite_pool" if as_elite else "pool")


# ── Helpers ──────────────────────────────────────────────────────────────────

func _set_status(text: String) -> void:
	status_label.text = text


func _new_uid_text() -> String:
	return ResourceUID.id_to_text(ResourceUID.create_id())


func _uid_text_for(path: String) -> String:
	var id := ResourceLoader.get_resource_uid(path)
	if id == ResourceUID.INVALID_ID:
		return _new_uid_text()
	return ResourceUID.id_to_text(id)


func _fmt_num(v: float) -> String:
	if absf(v - roundf(v)) < 0.0001:
		return str(int(roundf(v)))
	return str(v)


func _to_pascal_case(s: String) -> String:
	var out := ""
	for part in s.split("_"):
		if part == "":
			continue
		out += part.substr(0, 1).to_upper() + part.substr(1)
	return out
