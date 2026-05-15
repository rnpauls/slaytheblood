## Enemy facade — Combatant subclass that coordinates the three extracted
## components (HandManager, ActionSequencer, DefenseSequencer) and owns the
## intent / hover UI that ties them together.
##
## Responsibilities that LIVE here:
##   * Combatant lifecycle (_init_stats, _on_stats_set, update_enemy, _on_death)
##   * Intent display + plan-color visualization (update_intent,
##     _update_hand_plan_colors, _action_plan_color)
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
const WEAPON_HANDLER_SCENE := preload("res://scenes/weapon_handler/weapon_handler.tscn")
const WEAPON_BADGE_OFFSET := Vector2(100, -40)
## Half of the default `display_height` (152, see custom_resources/stats.gd).
## Scene-default positions of intent/staged are calibrated for this baseline:
## a sprite of this height needs no per-enemy adjustment. Larger or smaller
## enemies shift `intent_ui` / `staged_display` up or down to track the head.
const SPRITE_BASELINE_HALF := 76.0
const DEATH_FADE_DURATION := 0.5
const DEATH_SINK_DISTANCE := 12.0

@onready var arrow: Sprite2D = $Arrow
@onready var intent_ui: IntentUI = $IntentUI as IntentUI
@onready var enemy_resource_ui: EnemyResourceUI = $EnemyResourceUI
@onready var enemy_hand: EnemyHand = $EnemyHand
@onready var staged_display: EnemyStagedDisplay = $StagedDisplay
@onready var played_cards_display: EnemyPlayedCardsDisplay = $PlayedCardsDisplay
@onready var block_display: Node2D = $BlockDisplay
@onready var name_label: Label = $NameLabel
@onready var hover_collision: CollisionShape2D = $HoverArea/CollisionShape2D

@onready var _intent_origin_y: float = intent_ui.position.y
@onready var _staged_origin_y: float = staged_display.position.y
@onready var _played_origin_y: float = played_cards_display.position.y

signal enemy_action_completed

var enemy_ai: EnemyAI

## Convenience aliases routing to the hand manager (kept for external callers
## that expect Enemy.hand / Enemy.card_ui_map).
var hand: Array[Card]: get = _get_hand
var card_ui_map: Dictionary: get = _get_card_ui_map

## current_action delegates to action_sequencer; setter triggers intent refresh.
var current_action: Card: set = set_current_action, get = _get_current_action

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
	action_sequencer.setup(self, hand_manager, staged_display, played_cards_display, enemy_resource_ui)


# ── Combatant overrides ───────────────────────────────────────────────────────

func _init_stats(value: Stats) -> Stats:
	return value.create_instance()

func _on_stats_set() -> void:
	update_enemy()

func _on_death() -> void:
	SFXPlayer.play(stats.death_sound)
	# queue_free skips mouse_exited on our hover sources (HoverArea,
	# StatusHandler, IntentUI), so a tooltip shown for this enemy would
	# otherwise stay on screen.
	Events.tooltip_hide_requested.emit()
	if stats and stats.hand_left is Weapon:
		(stats.hand_left as Weapon).detach_from_combatant(self)
	# Emit synchronously (EnemyHandler needs it now); defer only queue_free.
	Events.enemy_died.emit(self)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, DEATH_FADE_DURATION)
	tween.tween_property(sprite_2d, "position:y", sprite_2d.position.y + DEATH_SINK_DISTANCE, DEATH_FADE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

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
	# (pitch, play, block) so the visual hand never drifts.
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

func burn_played_cards() -> void:
	await played_cards_display.burn_all()


# ── Action delegation ─────────────────────────────────────────────────────────

func declare_next_attack() -> void:
	await action_sequencer.declare_next_attack()

func run_pre_block_reveal() -> void:
	await action_sequencer.run_pre_block_reveal()

func do_action() -> void:
	await action_sequencer.do_action()


# ── Phase / lifecycle ─────────────────────────────────────────────────────────

func cleanup_phase() -> void:
	# Reserve cards don't count toward cards_per_turn. Draw back up to
	# cards_per_turn + 1 effective hand size, capped at cards_per_turn draws.
	var reserve_count := 0
	for card in hand_manager.hand:
		if card and card.reserve:
			reserve_count += 1
	var effective_hand := hand_manager.hand.size() - reserve_count
	var to_draw := clampi(stats.cards_per_turn + 1 - effective_hand, 0, stats.cards_per_turn)
	if to_draw > 0:
		hand_manager.draw_cards(to_draw)
	stats.mana = 0
	stats.action_points = 1
	enemy_resource_ui.update_display(enemy_ai)


# ── Visual / intent refresh ───────────────────────────────────────────────────

func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready

	sprite_2d.texture = stats.art
	var s : float = stats.display_height / stats.art.get_height()
	sprite_2d.scale = Vector2(s, s)

	# Bottom-anchor at the Enemy's origin: the texture draws entirely above
	# sprite_2d.position, so the feet always sit at local (0, 0).
	sprite_2d.offset = Vector2(0, -stats.art.get_height() / 2.0)
	sprite_2d.position = Vector2.ZERO

	var half := sprite_2d.get_rect().size * sprite_2d.scale * 0.5
	var dy := half.y - SPRITE_BASELINE_HALF

	# Track the head relative to the baseline sprite. The whole growth happens
	# upward (bottom is fixed), so the top moves by 2 * dy.
	intent_ui.position.y = _intent_origin_y - 2.0 * dy
	staged_display.position.y = _staged_origin_y - 2.0 * dy
	played_cards_display.position.y = _played_origin_y - 2.0 * dy

	# Vertical middle of the actual sprite — feet at 0, top at -2 * half.y.
	var sprite_center_y := -half.y
	arrow.position = Vector2(half.x + ARROW_OFFSET, sprite_center_y)

	(hover_collision.shape as RectangleShape2D).size = half * 2.0
	hover_collision.position.y = sprite_center_y

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


## Refresh the intent display, the resource UI, and the per-card plan colors.
## Called any time the AI plan or the hand might have changed (hand mutations,
## action declared/played, defense applied).
func update_intent() -> void:
	# Build a preview plan when one isn't active (between or before enemy
	# turns) so the intent text and hand colors share a single source of truth.
	# The _is_playing_action guard mirrors _on_hand_changed — during execution
	# turn_plan is non-null so this branch normally skips, but guard anyway so
	# the invariant is enforced at every recompute site.
	if enemy_ai and enemy_ai.turn_plan == null and enemy_ai.hand.size() > 0 and not enemy_ai._is_playing_action:
		var player_life: int = enemy_ai.target.stats.health
		enemy_ai.turn_plan = enemy_ai.calculate_max_offense_now(player_life)

	var new_intent = Intent.new()
	if current_action and current_action.type == Card.Type.ATTACK:
		var phys := current_action.get_attack_value()
		var arc := current_action.zap
		if phys > 0:
			phys = modifier_handler.get_modified_value(phys, Modifier.Type.DMG_DEALT)
		if arc > 0:
			arc = modifier_handler.get_modified_value(arc, Modifier.Type.ARCANE_DEALT)
		var modified_damage: int = enemy_ai.target.modifier_handler.get_modified_value(phys + arc, Modifier.Type.DMG_TAKEN)

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
	_update_hand_plan_colors()


## Color each card in the hand to reflect the AI's turn plan:
##   red = attack to be played (+ "!" if it has on-hit), green = NAA,
##   blue = to be pitched, black = not played.
func _update_hand_plan_colors() -> void:
	if not enemy_ai:
		return
	var plan = enemy_ai.turn_plan
	# Sanity: every card the plan still references should also be in
	# card_ui_map. If not, the plan is pointing at a stale card and the
	# user's seeing miscolored hand state — surface it for debugging.
	if plan != null:
		for c: Card in plan.actions:
			if not hand_manager.card_ui_map.has(c):
				push_warning("[Enemy:%s] plan.actions has '%s' not in card_ui_map" % [stats.character_name, c.id])
		for c: Card in plan.pitched:
			if not hand_manager.card_ui_map.has(c):
				push_warning("[Enemy:%s] plan.pitched has '%s' not in card_ui_map" % [stats.character_name, c.id])
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
				color = Color.DEEP_SKY_BLUE
			elif card.type == Card.Type.TRASH:
				color = Color.SADDLE_BROWN
		card_ui.set_plan_color(color, show_exclamation)


## Plan color for a card the AI intends to play this turn. Explicit per-type
## branch (rather than "ATTACK or default") so a stray BLOCK in plan.actions
## would surface as BLACK instead of being silently mis-colored as a NAA.
func _action_plan_color(card: Card) -> Color:
	match card.type:
		Card.Type.ATTACK:
			return Color.RED
		Card.Type.NAA:
			return Color.CHARTREUSE
		_:
			return Color.BLACK


# ── Hand-changed reaction ────────────────────────────────────────────────────

## React to any hand mutation (draw, add, remove, AI removal) by re-planning
## and refreshing intent + resource UI in one place. Replaces the duplicated
## "recalculate_plan + update_intent" blocks that used to live in every
## mutation site on enemy.gd.
func _on_hand_changed() -> void:
	if not enemy_ai:
		return
	# Skip recalc while play_next_action is consuming the plan. Each pitch /
	# play inside that loop emits card_removed_from_hand, and a cascading
	# rebuild here would replace turn_plan mid-execution — causing the
	# displayed plan to drift from what gets pitched/played.
	if enemy_ai.turn_plan != null and not enemy_ai._is_playing_action:
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
