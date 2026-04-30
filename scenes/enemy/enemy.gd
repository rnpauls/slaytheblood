class_name Enemy
extends Area2D

const ARROW_OFFSET := 45
const WHITE_SPRITE_MATERIAL := preload("res://art/themes/white_sprite_material.tres")
const ENEMY_CARD_UI_SCENE := preload("res://scenes/card_ui/enemy_card_ui.tscn")

## Delay between successive card draws (seconds), matching player hand feel.
const DRAW_INTERVAL := 0.12

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var intent_ui: IntentUI = $IntentUI as IntentUI
@onready var enemy_hand_ui: EnemyHandUI = $EnemyHandUI
@onready var enemy_hand: EnemyHand = $EnemyHand
@onready var staged_display: EnemyStagedDisplay = $StagedDisplay
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

signal enemy_action_completed
signal attack_completed

var enemy_ai: EnemyAI
var current_action: Card: set = set_current_action
var hand: Array

var active_on_hits: Array[OnHit]

## Maps Card → EnemyCardUI so we can look up the visual for any card in O(1).
var card_ui_map: Dictionary = {}

## The EnemyCardUI currently staged (if any).
var _staged_card_ui: EnemyCardUI = null

## Set just before play_next_action() so the signal handler knows not to
## animate this card out of EnemyHand — staged_display.stage() will reparent it.
var _pending_stage_card: Card = null


func set_current_action(value: Card) -> void:
	current_action = value
	update_intent()

func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance()

	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)

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

func update_stats() -> void:
	stats_ui.update_stats(stats)

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

## Draw multiple cards with a stagger delay between each.
func draw_cards(amount: int) -> void:
	for i in range(amount):
		draw_card()
		if i < amount - 1:
			await get_tree().create_timer(DRAW_INTERVAL).timeout

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

	if current_action == null:
		Events.enemy_turn_completed.emit(self)
	else:
		_log("declaring attack: %s" % current_action.id)
		# Stage the attack card near this enemy, face-up.
		# Use the pre-captured card_ui since the map entry may already be gone.
		_stage_attack_card_ui(current_action, pending_card_ui)
		Events.enemy_attack_declared.emit()
		await Events.player_blocks_declared
		do_action()

func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready

	sprite_2d.texture = stats.art
	arrow.position = Vector2.RIGHT * (sprite_2d.get_rect().size.x / 2 + ARROW_OFFSET)
	update_stats()

func update_intent() -> void:
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
	else:
		if enemy_ai and enemy_ai.hand.size() > 0:
			new_intent.base_text = "? X %s"
			new_intent.current_text = new_intent.base_text % get_num_cards_for_turn()
			new_intent.icon = null
		else:
			new_intent.current_text = "EMPTY"
			new_intent.icon = null
	intent_ui.update_intent(new_intent)

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
	card_ui.play()

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


func take_damage(damage: int, which_modifier: Modifier.Type) -> int:
	if stats.health <= 0:
		return 0

	sprite_2d.material = WHITE_SPRITE_MATERIAL

	var mod_dmg := modifier_handler.get_modified_value(damage, which_modifier)
	var damage_taken: = stats.take_damage(mod_dmg)
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_interval(0.17)

	tween.finished.connect(
		func():
			sprite_2d.material = null

			if stats.health <= 0:
				Events.enemy_died.emit(self)
				queue_free()
	)
	return damage_taken

func get_num_cards_for_turn() -> int:
	var player_life = get_tree().get_first_node_in_group("player").stats.health
	var turn_plan: Dictionary = enemy_ai.calculate_max_offense_now(player_life)
	return turn_plan.actions.size()

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
		return true

# ── Staged attack card ────────────────────────────────────────────────────────

## Move the attack card to this enemy's StagedDisplay (above its sprite), face-up.
## Optionally accepts a pre-captured card_ui to handle the case where card_ui_map
## has already been cleared by the card_removed_from_hand signal.
func _stage_attack_card_ui(card: Card, card_ui: EnemyCardUI) -> void:
	# Fall back to map lookup if no pre-captured ui was provided
	if not is_instance_valid(card_ui):
		card_ui = card_ui_map.get(card, null)
	if not is_instance_valid(card_ui):
		_log("WARNING: _stage_attack_card — no card_ui found for %s" % card.id)
		return

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
		return

	var card_ui: EnemyCardUI = card_ui_map.get(card, null)
	if is_instance_valid(card_ui) and card_ui.get_parent() == enemy_hand:
		enemy_hand.remove_card(card_ui)
	card_ui_map.erase(card)

## Lightweight debug printer — prefixes with enemy name so multi-enemy logs are easy to read.
func _log(msg: String) -> void:
	print("[Enemy:%s] %s" % [stats.character_name if stats else name, msg])

func _on_area_entered(_area):
	arrow.show()

func _on_area_exited(_area):
	arrow.hide()
