## Enemy facade — Combatant subclass that coordinates the three extracted
## components (HandManager, ActionSequencer, DefenseSequencer) and owns the
## intent / arsenal / hover UI that ties them together.
##
## Responsibilities that LIVE here:
##   * Combatant lifecycle (_init_stats, _on_stats_set, update_enemy, _on_death)
##   * Intent display + plan-color visualization (update_intent,
##     _update_hand_plan_colors, _action_plan_color, _refresh_arsenal_card_ui)
##   * Arsenal slot management (destroy_arsenal, _arsenal_card_ui)
##   * Hover area / arrow / name label / tooltip routing
##   * setup_ai (orchestrates: AI instance + wiring all components)
##   * cleanup_phase (end-of-enemy-phase reset + redraw)
##   * Thin delegation to components for hand / action / defense methods
##
## Responsibilities that LIVE in components:
##   * Hand mutations + AI hand-removal sync → EnemyHandManager
##   * declare_next_attack / pre_block_reveal / do_action → EnemyActionSequencer
##   * Multi-card block animation → EnemyDefenseSequencer
class_name Enemy
extends Combatant

const ARROW_OFFSET := 45
const ENEMY_CARD_UI_SCENE := preload("res://scenes/card_ui/enemy_card_ui.tscn")
const WEAPON_HANDLER_SCENE := preload("res://scenes/weapon_handler/weapon_handler.tscn")
const WEAPON_BADGE_OFFSET := Vector2(80, -40)
const LEGACY_SPRITE_HALF_EXTENT := 41.0

@onready var arrow: Sprite2D = $Arrow
@onready var intent_ui: IntentUI = $IntentUI as IntentUI
@onready var enemy_resource_ui: EnemyResourceUI = $EnemyResourceUI
@onready var enemy_hand: EnemyHand = $EnemyHand
@onready var staged_display: EnemyStagedDisplay = $StagedDisplay
@onready var block_display: Node2D = $BlockDisplay
@onready var name_label: Label = $NameLabel
@onready var hover_collision: CollisionShape2D = $HoverArea/CollisionShape2D

@onready var _intent_origin_y: float = intent_ui.position.y
@onready var _staged_origin_y: float = staged_display.position.y
@onready var _stats_origin_y: float = stats_ui.position.y
@onready var _resource_origin_y: float = enemy_resource_ui.position.y
@onready var _name_origin_y: float = name_label.position.y
@onready var _status_origin_y: float = status_handler.position.y
@onready var _hand_origin_y: float = enemy_hand.position.y
@onready var _block_origin_x: float = block_display.position.x

## Position (relative to the Enemy node) where the arsenal card_ui sits.
@export var arsenal_offset: Vector2 = Vector2(-90, 158)

signal enemy_action_completed

var enemy_ai: EnemyAI

## Convenience aliases routing to the hand manager (kept for external callers
## that expect Enemy.hand / Enemy.card_ui_map).
var hand: Array[Card]: get = _get_hand
var card_ui_map: Dictionary: get = _get_card_ui_map

## current_action delegates to action_sequencer; setter triggers intent refresh.
var current_action: Card: set = set_current_action, get = _get_current_action

## EnemyCardUI displayed in the arsenal slot (or null when arsenal is empty).
var _arsenal_card_ui: EnemyCardUI = null

## Visual badge for an enemy-wielded weapon (only set if stats.hand_left is a
## Weapon at battle setup). Reuses WeaponHandler with `interactive = false`
## so we get the icon + tooltip plumbing without player-input handling.
var _weapon_badge: WeaponHandler = null

var hand_manager: EnemyHandManager
var action_sequencer: EnemyActionSequencer
var defense_sequencer: EnemyDefenseSequencer


func _ready() -> void:
	# Wait until @onready vars (enemy_hand, block_display, etc.) are resolved.
	hand_manager = EnemyHandManager.new()
	hand_manager.name = "HandManager"
	add_child(hand_manager)
	hand_manager.setup(self, enemy_hand)
	hand_manager.hand_changed.connect(_on_hand_changed)

	defense_sequencer = EnemyDefenseSequencer.new()
	defense_sequencer.name = "DefenseSequencer"
	add_child(defense_sequencer)
	defense_sequencer.setup(self, hand_manager, enemy_hand, block_display)

	action_sequencer = EnemyActionSequencer.new()
	action_sequencer.setup(self, hand_manager, staged_display, enemy_resource_ui)


# ── Combatant overrides ───────────────────────────────────────────────────────

func _init_stats(value: Stats) -> Stats:
	return value.create_instance()

func _on_stats_set() -> void:
	update_enemy()

func _on_death() -> void:
	# queue_free skips mouse_exited on our hover sources (HoverArea,
	# StatusHandler, IntentUI), so a tooltip shown for this enemy would
	# otherwise stay on screen.
	Events.tooltip_hide_requested.emit()
	if stats and stats.hand_left is Weapon:
		(stats.hand_left as Weapon).detach_from_combatant(self)
	Events.enemy_died.emit(self)
	queue_free()


# ── AI setup ──────────────────────────────────────────────────────────────────

func setup_ai(player_target: Player = null) -> void:
	if enemy_ai:
		enemy_ai.queue_free()

	var new_ai: EnemyAI = stats.ai.instantiate()
	add_child(new_ai)
	enemy_ai = new_ai
	enemy_ai.enemy = self
	enemy_ai.modifier_handler = modifier_handler
	enemy_ai.setup(player_target)
	enemy_ai.hand = hand_manager.hand

	# Keep EnemyHand display in sync whenever EnemyAI removes a card internally
	# (pitch, arsenal pickup, play, block) so the visual hand never drifts.
	hand_manager.connect_to_ai(enemy_ai)

	# Wire IntentUI so hover events carry this enemy reference (for tooltip).
	intent_ui.enemy = self

	# Now that the AI exists, materialize the symmetric HandFacade for effects.
	hand_facade = EnemyHandFacade.new(self)

	enemy_resource_ui.update_display(enemy_ai)


# ── Hand delegation ───────────────────────────────────────────────────────────

func draw_card() -> void:
	hand_manager.draw_card()

func draw_cards(amount: int) -> Tween:
	return hand_manager.draw_cards(amount)

func add_card_to_hand(card: Card) -> void:
	hand_manager.add_card_to_hand(card)

func exhaust_fleeting_in_hand() -> void:
	await hand_manager.exhaust_fleeting_in_hand()


# ── Action delegation ─────────────────────────────────────────────────────────

func declare_next_attack() -> void:
	action_sequencer.declare_next_attack()

func run_pre_block_reveal() -> void:
	await action_sequencer.run_pre_block_reveal()

func do_action() -> void:
	await action_sequencer.do_action()


# ── Phase / lifecycle ─────────────────────────────────────────────────────────

func cleanup_phase() -> void:
	# Draw back up to cards_per_turn, staggered.
	var to_draw := stats.cards_per_turn - hand_manager.hand.size()
	if to_draw > 0:
		hand_manager.draw_cards(to_draw)
	stats.block = 0
	stats.mana = 0
	stats.action_points = 1
	enemy_resource_ui.update_display(enemy_ai)


func destroy_arsenal() -> bool:
	if enemy_ai.arsenal == null:
		return false
	var arsenal_card: Card = enemy_ai.arsenal
	enemy_ai.arsenal = null
	arsenal_card.queue_free()
	_refresh_arsenal_card_ui()
	return true


# ── Visual / intent refresh ───────────────────────────────────────────────────

func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready

	sprite_2d.texture = stats.art
	var s : float = stats.display_height / stats.art.get_height()
	sprite_2d.scale = Vector2(s, s)

	var half := sprite_2d.get_rect().size * sprite_2d.scale * 0.5
	var dy := half.y - LEGACY_SPRITE_HALF_EXTENT
	var dx := half.x - LEGACY_SPRITE_HALF_EXTENT

	intent_ui.position.y = _intent_origin_y - dy
	staged_display.position.y = _staged_origin_y - dy

	stats_ui.position.y = _stats_origin_y + dy
	enemy_resource_ui.position.y = _resource_origin_y + dy
	name_label.position.y = _name_origin_y + dy
	status_handler.position.y = _status_origin_y + dy
	enemy_hand.position.y = _hand_origin_y + dy

	block_display.position.x = _block_origin_x - dx
	arrow.position = Vector2.RIGHT * (half.x + ARROW_OFFSET)

	(hover_collision.shape as RectangleShape2D).size = half * 2.0

	name_label.text = stats.character_name
	update_stats()
	_setup_weapon_badge()


## Mount the visual weapon badge. WeaponHandler.set_weapon takes care of
## calling attach_to_combatant — no need to call it again here.
## Idempotent — safe to call multiple times if update_enemy fires more
## than once.
func _setup_weapon_badge() -> void:
	if not (stats.hand_left is Weapon):
		return
	if _weapon_badge != null and is_instance_valid(_weapon_badge):
		return
	var weapon := stats.hand_left as Weapon
	var badge := WEAPON_HANDLER_SCENE.instantiate() as WeaponHandler
	badge.interactive = false
	badge.owner_of_weapon = self
	add_child(badge)
	badge.position = WEAPON_BADGE_OFFSET
	badge.set_weapon(weapon)
	_weapon_badge = badge


## Refresh the intent display, the resource UI, the arsenal card_ui, and the
## per-card plan colors. Called any time the AI plan or the hand might have
## changed (hand mutations, action declared/played, defense applied).
func update_intent() -> void:
	# Build a preview plan when one isn't active (between or before enemy
	# turns) so the intent text and hand colors share a single source of truth.
	if enemy_ai and enemy_ai.turn_plan == null and enemy_ai.hand.size() > 0:
		var player_life: int = enemy_ai.target.stats.health
		enemy_ai.turn_plan = enemy_ai.calculate_max_offense_now(player_life)

	var new_intent = Intent.new()
	if current_action and current_action.type == Card.Type.ATTACK:
		var og_atk = current_action.get_attack_value()
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
	for card in hand_manager.card_ui_map:
		var card_ui: EnemyCardUI = hand_manager.card_ui_map[card]
		if not is_instance_valid(card_ui):
			continue
		var color: Color = Color.BLACK
		var show_exclamation: bool = false
		if plan != null:
			if card in plan.actions:
				color = _action_plan_color(card)
				show_exclamation = card.type == Card.Type.ATTACK \
					and (card.on_hits.size() > 0 or active_on_hits.size() > 0)
			elif card in plan.pitched:
				color = Color.BLUE
		card_ui.set_plan_color(color, show_exclamation)

	# Arsenal card_ui follows the same rules (it can't be pitched, so no blue).
	if is_instance_valid(_arsenal_card_ui) and enemy_ai.arsenal != null:
		var ars: Card = enemy_ai.arsenal
		var ars_color: Color = Color.BLACK
		var ars_excl: bool = false
		if plan != null and ars in plan.actions:
			ars_color = _action_plan_color(ars)
			ars_excl = ars.type == Card.Type.ATTACK \
				and (ars.on_hits.size() > 0 or active_on_hits.size() > 0)
		_arsenal_card_ui.set_plan_color(ars_color, ars_excl)


## Plan color for a card the AI intends to play this turn. Explicit per-type
## branch (rather than "ATTACK or default") so a stray BLOCK in plan.actions
## would surface as BLACK instead of being silently mis-colored as a NAA.
func _action_plan_color(card: Card) -> Color:
	match card.type:
		Card.Type.ATTACK:
			return Color.RED
		Card.Type.NAA:
			return Color.GREEN
		_:
			return Color.BLACK


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


# ── Hand-changed reaction ────────────────────────────────────────────────────

## React to any hand mutation (draw, add, remove, AI removal) by re-planning
## and refreshing intent + resource UI in one place. Replaces the duplicated
## "recalculate_plan + update_intent" blocks that used to live in every
## mutation site on enemy.gd.
func _on_hand_changed() -> void:
	if not enemy_ai:
		return
	if enemy_ai.turn_plan != null:
		var player_life: int = enemy_ai.target.stats.health
		enemy_ai.recalculate_plan(player_life)
	update_intent()


# ── current_action accessors ──────────────────────────────────────────────────

func set_current_action(value: Card) -> void:
	if action_sequencer:
		action_sequencer.current_action = value
	update_intent()

func _get_current_action() -> Card:
	return action_sequencer.current_action if action_sequencer else null


# ── Backwards-compat aliases for hand / card_ui_map ──────────────────────────

func _get_hand() -> Array[Card]:
	return hand_manager.hand if hand_manager else []

func _get_card_ui_map() -> Dictionary:
	return hand_manager.card_ui_map if hand_manager else {}


# ── Hover / tooltip routing ───────────────────────────────────────────────────

func _on_area_entered(_area):
	arrow.show()

func _on_area_exited(_area):
	arrow.hide()

func _on_hover_area_mouse_entered() -> void:
	name_label.show()
	var entries := get_hover_tooltip_entries()
	if entries.is_empty():
		return
	# Anchor to the sprite's canvas-space rect so the tooltip sits beside the
	# enemy. get_global_transform_with_canvas folds in any camera/zoom so the
	# rect lands in the same coordinate system the TooltipLayer uses.
	var rect := sprite_2d.get_global_transform_with_canvas() * sprite_2d.get_rect()
	Events.tooltip_show_requested.emit(entries, rect)

func _on_hover_area_mouse_exited() -> void:
	name_label.hide()
	Events.tooltip_hide_requested.emit()
