class_name Enemy
extends Combatant

const ARROW_OFFSET := 45
const ENEMY_CARD_UI_SCENE := preload("res://scenes/card_ui/enemy_card_ui.tscn")

## Delay between successive card draws (seconds), matching player hand feel.
const DRAW_INTERVAL := 0.12

@onready var arrow: Sprite2D = $Arrow
@onready var intent_ui: IntentUI = $IntentUI as IntentUI
@onready var enemy_hand_ui: EnemyHandUI = $EnemyHandUI
@onready var enemy_hand: EnemyHand = $EnemyHand
@onready var staged_display: EnemyStagedDisplay = $StagedDisplay

## Position (relative to the Enemy node) where the arsenal card_ui sits when one is held.
@export var arsenal_offset: Vector2 = Vector2(-90, 158)

signal enemy_action_completed

var enemy_ai: EnemyAI
var current_action: Card: set = set_current_action
var hand: Array

## Maps Card → EnemyCardUI so we can look up the visual for any card in O(1).
var card_ui_map: Dictionary = {}

## The EnemyCardUI currently staged (if any).
var _staged_card_ui: EnemyCardUI = null

## Set just before play_next_action() so the signal handler knows not to
## animate this card out of EnemyHand — staged_display.stage() will reparent it.
var _pending_stage_card: Card = null

## EnemyCardUI displayed in the arsenal slot (or null when arsenal is empty).
var _arsenal_card_ui: EnemyCardUI = null


func set_current_action(value: Card) -> void:
	current_action = value
	update_intent()

func _init_stats(value: Stats) -> Stats:
	return value.create_instance()

func _on_stats_set() -> void:
	update_enemy()

func setup_ai() -> void:
	if enemy_ai:
		enemy_ai.queue_free()

	var new_ai: EnemyAI = stats.ai.instantiate()
	add_child(new_ai)
	enemy_ai = new_ai
	enemy_ai.enemy = self
	enemy_ai.modifier_handler = modifier_handler
	enemy_ai.setup()
	enemy_ai.hand = hand

	# Keep EnemyHand display in sync whenever EnemyAI removes a card internally
	# (pitch, arsenal pickup, play, block) so the visual hand never drifts.
	enemy_ai.card_removed_from_hand.connect(_on_ai_card_removed_from_hand)

	# Wire IntentUI so hover events carry this enemy reference (for tooltip)
	intent_ui.enemy = self

	enemy_hand_ui.update_cards(enemy_ai)

## Draw a single card, add it to the hand, and animate it into EnemyHand.
func draw_card() -> void:
	var card_drawn: Card = stats.draw_pile.draw_card()
	if card_drawn:
		hand.append(card_drawn)
		Events.enemy_card_drawn.emit(self)
		card_drawn.owner = self
		var card_ui := enemy_hand.add_card(card_drawn, stats, modifier_handler)
		card_ui_map[card_drawn] = card_ui
		_log("drew %s  (hand %d, ui_map %d)" % [card_drawn.id, hand.size(), card_ui_map.size()])
		if enemy_ai:
			# Recalculate the turn plan if one already exists (mid-turn card draw).
			if enemy_ai.turn_plan != null:
				var player_life: int = get_tree().get_first_node_in_group("player").stats.health
				enemy_ai.recalculate_plan(player_life)
			# Always refresh intent so the "? X N" card count stays current.
			update_intent()

## Draw multiple cards with a stagger delay between each.
func draw_cards(amount: int) -> Tween:
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		if i < amount - 1:
			tween.tween_interval(DRAW_INTERVAL)
	return tween

func declare_next_attack() -> void:
	if not enemy_ai:
		return

	# Flag the upcoming action card so the signal handler skips its visual removal —
	# staged_display.stage() will reparent it instead of animating it out of EnemyHand.
	var pending_card_ui: EnemyCardUI = null
	if enemy_ai.turn_plan and enemy_ai.turn_plan.actions.size() > 0:
		_pending_stage_card = enemy_ai.turn_plan.actions[0]
		pending_card_ui = card_ui_map.get(_pending_stage_card, null)

	current_action = enemy_ai.play_next_action()
	_pending_stage_card = null
	update_intent()
	enemy_hand_ui.update_cards(enemy_ai)

	# When current_action is null the enemy's plan is exhausted; EnemyActingState
	# observes that directly and exits its loop. Otherwise stage the card and
	# announce the attack — the state owns the await player_blocks_declared
	# and the do_action call so cancellation on death is deterministic.
	if current_action != null:
		_log("declaring attack: %s" % current_action.id)
		_stage_attack_card_ui(current_action, pending_card_ui)
		Events.enemy_attack_declared.emit()

func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready

	sprite_2d.texture = stats.art
	arrow.position = Vector2.RIGHT * (sprite_2d.get_rect().size.x / 2 + ARROW_OFFSET)
	update_stats()

func update_intent() -> void:
	# Build a preview plan when one isn't active (between or before enemy turns)
	# so the intent text and hand colors share a single source of truth.
	if enemy_ai and enemy_ai.turn_plan == null and enemy_ai.hand.size() > 0:
		var player_life: int = get_tree().get_first_node_in_group("player").stats.health
		enemy_ai.turn_plan = enemy_ai.calculate_max_offense_now(player_life)

	var new_intent = Intent.new()
	if current_action and current_action.type == Card.Type.ATTACK:
		var og_atk = current_action.attack
		var modified_damage := modifier_handler.get_modified_value(og_atk, Modifier.Type.DMG_DEALT)
		modified_damage = enemy_ai.target.modifier_handler.get_modified_value(modified_damage, Modifier.Type.DMG_TAKEN)

		if current_action.go_again:
			new_intent.base_text = "%s GA"
		else:
			new_intent.base_text = "%s"
		new_intent.current_text = new_intent.base_text % modified_damage
		new_intent.icon = preload("res://art/tile_0103.png")
	elif current_action and current_action.type == Card.Type.NAA:
		new_intent.current_text = "NAA"
	else:
		if enemy_ai and enemy_ai.hand.size() > 0:
			new_intent.base_text = "? X %s"
			new_intent.current_text = new_intent.base_text % enemy_ai.turn_plan.actions.size()
			new_intent.icon = null
		else:
			new_intent.current_text = "EMPTY"
			new_intent.icon = null
	intent_ui.update_intent(new_intent)
	_refresh_arsenal_card_ui()
	_update_hand_plan_colors()

## Color each card in the hand to reflect the AI's turn plan:
##   red = attack to be played (+ "!" if it has on-hit), green = NAA,
##   blue = to be pitched, black = not played.
func _update_hand_plan_colors() -> void:
	if not enemy_ai:
		return
	var plan = enemy_ai.turn_plan
	for card in card_ui_map:
		var card_ui: EnemyCardUI = card_ui_map[card]
		if not is_instance_valid(card_ui):
			continue
		var color := Color.BLACK
		var show_exclamation := false
		if plan != null:
			if card in plan.actions:
				if card.type == Card.Type.ATTACK:
					color = Color.RED
					show_exclamation = card.on_hits.size() > 0 or active_on_hits.size() > 0
				else:
					color = Color.GREEN
			elif card in plan.pitched:
				color = Color.BLUE
		card_ui.set_plan_color(color, show_exclamation)

	# Arsenal card_ui follows the same rules (it can't be pitched, so no blue case).
	if is_instance_valid(_arsenal_card_ui) and enemy_ai.arsenal != null:
		var ars: Card = enemy_ai.arsenal
		var ars_color := Color.BLACK
		var ars_excl := false
		if plan != null and ars in plan.actions:
			if ars.type == Card.Type.ATTACK:
				ars_color = Color.RED
				ars_excl = ars.on_hits.size() > 0 or active_on_hits.size() > 0
			else:
				ars_color = Color.GREEN
		_arsenal_card_ui.set_plan_color(ars_color, ars_excl)

## Create, update, or destroy the arsenal slot card_ui to mirror enemy_ai.arsenal.
func _refresh_arsenal_card_ui() -> void:
	if not enemy_ai:
		return
	var current_arsenal: Card = enemy_ai.arsenal
	if current_arsenal == null:
		if is_instance_valid(_arsenal_card_ui):
			_arsenal_card_ui.queue_free()
		_arsenal_card_ui = null
		return
	if not is_instance_valid(_arsenal_card_ui):
		_arsenal_card_ui = ENEMY_CARD_UI_SCENE.instantiate() as EnemyCardUI
		add_child(_arsenal_card_ui)
		_arsenal_card_ui.scale = Vector2.ONE * enemy_hand.card_scale
		_arsenal_card_ui.position = arsenal_offset
	if _arsenal_card_ui.card != current_arsenal:
		_arsenal_card_ui.setup(current_arsenal, stats, modifier_handler)
		_arsenal_card_ui.show_back = true
		_arsenal_card_ui.set_arsenal_marker(true)

func do_action() -> void:
	if not current_action:
		return

	# Release the staged card directly — no return-to-hand animation, caller takes it.
	var card_ui: EnemyCardUI
	if is_instance_valid(_staged_card_ui):
		card_ui = staged_display.release()
		_staged_card_ui = null
	else:
		card_ui = _get_or_create_card_ui(current_action)
		hand.erase(current_action)
		card_ui_map.erase(current_action)

	card_ui.targets = [enemy_ai.target]
	await card_ui.play()

	enemy_action_completed.emit(self)
	attack_completed.emit()
	enemy_hand_ui.update_cards(enemy_ai)

## Defend player attack
func defend_attack(attack: int, go_again: bool, incoming_on_hits: Array[OnHit]) -> void:
	_log("defending attack=%d  go_again=%s  hand=%d  ai_hand=%d" % [
		attack, go_again, hand.size(), enemy_ai.hand.size()])
	var defense_array := enemy_ai.defend(attack, go_again, incoming_on_hits)
	for def_card: Card in defense_array:
		var card_ui := _get_or_create_card_ui(def_card)
		_remove_card_from_hand(def_card)
		card_ui.block()
	update_intent()
	enemy_hand_ui.update_cards(enemy_ai)
	_log("after defend  hand=%d  ai_hand=%d  ui_map=%d" % [hand.size(), enemy_ai.hand.size(), card_ui_map.size()])

func cleanup_phase() -> void:
	_log("cleanup  hand=%d  ai_hand=%d  ui_map=%d" % [hand.size(), enemy_ai.hand.size(), card_ui_map.size()])
	# Draw back up to cards_per_turn, staggered
	var to_draw := stats.cards_per_turn - hand.size()
	if to_draw > 0:
		draw_cards(to_draw)
	stats.block = 0
	stats.action_points = 1
	enemy_hand_ui.update_cards(enemy_ai)

func destroy_arsenal() -> bool:
	if enemy_ai.arsenal == null:
		return false
	else:
		var arsenal_card: Card = enemy_ai.arsenal
		enemy_ai.arsenal = null
		arsenal_card.queue_free()
		_refresh_arsenal_card_ui()
		return true

func _on_death() -> void:
	Events.enemy_died.emit(self)
	queue_free()

# ── Staged attack card ────────────────────────────────────────────────────────

## Move the attack card to this enemy's StagedDisplay (above its sprite), face-up.
## Optionally accepts a pre-captured card_ui to handle the case where card_ui_map
## has already been cleared by the card_removed_from_hand signal.
func _stage_attack_card_ui(card: Card, card_ui: EnemyCardUI) -> void:
	# Fall back to map lookup if no pre-captured ui was provided
	if not is_instance_valid(card_ui):
		card_ui = card_ui_map.get(card, null)
	if not is_instance_valid(card_ui):
		# Card isn't in the hand display (e.g. arsenal) — create a transient ui to stage.
		card_ui = _get_or_create_card_ui(card)

	_staged_card_ui = card_ui

	# Reveal the card face before staging
	if card_ui.show_back:
		card_ui.show_back = false

	staged_display.stage(card_ui)

## Convenience overload used by older call sites.
func _stage_attack_card(card: Card) -> void:
	_stage_attack_card_ui(card, card_ui_map.get(card, null))

func _unstage_attack_card() -> void:
	if is_instance_valid(_staged_card_ui):
		staged_display.unstage()
	_staged_card_ui = null

# ── Private helpers ───────────────────────────────────────────────────────────

## Return the EnemyCardUI for card if it's tracked, otherwise create a temporary one.
func _get_or_create_card_ui(card: Card) -> EnemyCardUI:
	var existing: EnemyCardUI = card_ui_map.get(card, null)
	if is_instance_valid(existing):
		return existing
	# Fallback: create a transient card_ui (e.g. arsenal cards not in hand display)
	_log("WARNING: creating transient card_ui for %s (not in ui_map)" % card.id)
	var card_ui: EnemyCardUI = ENEMY_CARD_UI_SCENE.instantiate()
	add_child(card_ui)
	card_ui.setup(card, stats, modifier_handler)
	card_ui.show_back = false
	return card_ui

## Remove a card from the hand array, the card_ui_map, and the EnemyHand display.
## Called by enemy.gd itself (do_action, defend_attack) when enemy.gd is in charge.
func _remove_card_from_hand(card: Card) -> void:
	hand.erase(card)
	var card_ui: EnemyCardUI = card_ui_map.get(card, null)
	if is_instance_valid(card_ui) and card_ui.get_parent() == enemy_hand:
		enemy_hand.remove_card(card_ui)
	card_ui_map.erase(card)
	_log("_remove_card_from_hand: %s  (hand %d, ui_map %d)" % [card.id, hand.size(), card_ui_map.size()])

## Called whenever EnemyAI removes a card from its internal hand array.
## Keeps the EnemyHand visual display in sync without duplicating erase logic.
## NOTE: we do NOT erase from hand[] here — EnemyAI already did that.
func _on_ai_card_removed_from_hand(card: Card) -> void:
	_log("AI removed '%s'  ai_hand=%d  enemy_hand=%d  ui_map=%d" % [
		card.id, enemy_ai.hand.size(), hand.size(), card_ui_map.size()])

	# If this card is about to be staged, skip the visual removal from EnemyHand.
	# staged_display.stage() will reparent it — animating it out here would conflict.
	if card == _pending_stage_card:
		_log("  → skipping visual removal for '%s' (will be staged)" % card.id)
		card_ui_map.erase(card)
		# Recalculate after the removal so the remaining plan stays accurate.
		if enemy_ai.turn_plan != null:
			var player_life: int = get_tree().get_first_node_in_group("player").stats.health
			enemy_ai.recalculate_plan(player_life)
			update_intent()
		return

	var card_ui: EnemyCardUI = card_ui_map.get(card, null)
	if is_instance_valid(card_ui) and card_ui.get_parent() == enemy_hand:
		enemy_hand.remove_card(card_ui)
	card_ui_map.erase(card)
	# Recalculate after the removal so the remaining plan stays accurate.
	if enemy_ai.turn_plan != null:
		var player_life: int = get_tree().get_first_node_in_group("player").stats.health
		enemy_ai.recalculate_plan(player_life)
		update_intent()

## Lightweight debug printer — prefixes with enemy name so multi-enemy logs are easy to read.
func _log(msg: String) -> void:
	print("[Enemy:%s] %s" % [stats.character_name if stats else name, msg])

func _on_area_entered(_area):
	arrow.show()

func _on_area_exited(_area):
	arrow.hide()

func _on_hover_area_mouse_entered() -> void:
	var sh := get_node_or_null("StatusHandler") as StatusHandler
	if sh == null:
		return
	var entries := sh.get_tooltip_entries()
	if entries.is_empty():
		return
	# Anchor to the sprite's canvas-space rect so the tooltip sits beside the
	# enemy. get_global_transform_with_canvas folds in any camera/zoom so the
	# rect lands in the same coordinate system the TooltipLayer uses.
	var rect := sprite_2d.get_global_transform_with_canvas() * sprite_2d.get_rect()
	Events.tooltip_show_requested.emit(entries, rect)

func _on_hover_area_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
