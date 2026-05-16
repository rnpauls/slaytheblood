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
const WEAPON_BADGE_OFFSET := Vector2(70, -130)
## Half of the default `display_height` (152, see custom_resources/stats.gd).
## Scene-default positions of intent/staged are calibrated for this baseline:
## a sprite of this height needs no per-enemy adjustment. Larger or smaller
## enemies shift `intent_ui` / `staged_display` up or down to track the head.
const SPRITE_BASELINE_HALF := 76.0
const DEATH_FADE_DURATION := 0.5
const DEATH_SINK_DISTANCE := 12.0
## Authored size.y of intent_ui.tscn (offset_bottom - offset_top). We read this
## as a constant instead of intent_ui.size.y because the Control's size is not
## guaranteed to be computed yet when update_enemy() runs (the layout pass for
## a Control parented to a Node2D can lag past _ready), and an under-reported
## size leaves the hover collision overlapping intent_ui — which prevents
## HoverArea.mouse_exited from firing when the cursor moves up into intent.
const INTENT_UI_HEIGHT := 48.0
## Extra px gap between intent_ui's bottom and the top of the hover collision.
## Belt-and-suspenders: even with a correctly-sized intent_ui, a 0-px shared
## edge can produce inconsistent mouse_enter/exit ordering across the Area2D /
## Control event pipelines.
const INTENT_COLLISION_GAP := 4.0

@onready var arrow: Sprite2D = $Arrow
@onready var intent_ui: IntentUI = $IntentUI as IntentUI
@onready var enemy_resource_ui: EnemyResourceUI = $EnemyResourceUI
@onready var enemy_hand: EnemyHand = $EnemyHand
@onready var staged_display: EnemyStagedDisplay = $StagedDisplay
@onready var exhaust_pile: CardStackPanel = $ExhaustPile
@onready var block_display: Node2D = $BlockDisplay
@onready var name_label: Label = $NameLabel
@onready var hover_collision: CollisionShape2D = $HoverArea/CollisionShape2D

@onready var _intent_origin_y: float = intent_ui.position.y
@onready var _staged_origin_y: float = staged_display.position.y

signal enemy_action_completed

var enemy_ai: EnemyAI

## Convenience aliases routing to the hand manager (kept for external callers
## that expect Enemy.hand / Enemy.card_ui_map).
var hand: Array[Card]: get = _get_hand
var card_ui_map: Dictionary: get = _get_card_ui_map

## current_action delegates to action_sequencer; setter triggers intent refresh.
## Either a Card (from hand) or a Weapon (from stats.hand_left).
var current_action: Object: set = set_current_action, get = _get_current_action

## Visual badge for an enemy-wielded weapon (only set if stats.hand_left is a
## Weapon at battle setup). Reuses WeaponHandler with `interactive = false`
## so we get the icon + tooltip plumbing without player-input handling.
## Public so the action sequencer can animate it during weapon swings.
var weapon_badge: WeaponHandler = null

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

	if not exhaust_pile.pressed.is_connected(_on_exhaust_pile_pressed):
		exhaust_pile.pressed.connect(_on_exhaust_pile_pressed)


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
	# Refresh per-turn weapon counter so attacks_per_turn enforces correctly
	# across multi-turn fights. Mirrors PlayerHandler.reset_weapons() at SOT.
	if stats.hand_left is Weapon:
		(stats.hand_left as Weapon).reset()
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

	# Vertical middle of the actual sprite — feet at 0, top at -2 * half.y.
	var sprite_center_y := -half.y
	arrow.position = Vector2(half.x + ARROW_OFFSET, sprite_center_y)

	# Trim the top of the hover collision so it doesn't overlap with the
	# IntentUI's rect just above the head. Without this, cursor moving up
	# from sprite into IntentUI stays inside the collision (overlap zone), so
	# HoverArea.mouse_exited never fires and the sprite tooltip persists —
	# and on the return trip back to sprite, no new HoverArea.mouse_entered
	# fires (still inside collision), so the sprite tooltip never re-shows.
	#
	# Use INTENT_UI_HEIGHT (the .tscn-authored size) instead of intent_ui.size.y:
	# the latter is sometimes 0 when read here because the layout pass for a
	# Control-under-Node2D hasn't run yet. Plus INTENT_COLLISION_GAP for a
	# definite gap so Area2D / Control event ordering can't race at a shared
	# edge. Clamp to sprite top so the collision never grows beyond the visible
	# sprite — for very short sprites the IntentUI may already sit fully above
	# the head and no trimming is needed.
	var intent_bottom_y: float = intent_ui.position.y + INTENT_UI_HEIGHT + INTENT_COLLISION_GAP
	var collision_top: float = maxf(intent_bottom_y, -half.y * 2.0)
	var collision_height: float = maxf(0.0, -collision_top)  # collision extends to y = 0
	(hover_collision.shape as RectangleShape2D).size = Vector2(half.x * 2.0, collision_height)
	hover_collision.position.y = collision_top + collision_height * 0.5

	name_label.text = stats.character_name
	update_stats()
	_setup_weapon_badge()

	# Wire the visual exhaust pile to the resource pile so cards added to
	# stats.exhaust (via card_play_finished / blocked) show up in the stack.
	if stats and stats.exhaust:
		exhaust_pile.card_pile = stats.exhaust


## Mount the visual weapon badge. WeaponHandler.set_weapon takes care of
## calling attach_to_combatant — no need to call it again here.
## Idempotent — safe to call multiple times if update_enemy fires more
## than once.
func _setup_weapon_badge() -> void:
	if not (stats.hand_left is Weapon):
		return
	if weapon_badge != null and is_instance_valid(weapon_badge):
		return
	var weapon := stats.hand_left as Weapon
	# Stats.create_instance() shallow-duplicates the resource, so this Weapon
	# ref persists across battles. Reset the per-turn counter so a fresh
	# battle doesn't inherit attacks_this_turn from a previous fight.
	weapon.reset()
	var badge := WEAPON_HANDLER_SCENE.instantiate() as WeaponHandler
	badge.interactive = false
	badge.owner_of_weapon = self
	add_child(badge)
	badge.position = WEAPON_BADGE_OFFSET
	badge.set_weapon(weapon)
	weapon_badge = badge


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
	if current_action is Card and (current_action as Card).type == Card.Type.ATTACK:
		var attack_card: Card = current_action as Card
		var phys: int = attack_card.get_attack_value()
		var arc: int = attack_card.zap
		if phys > 0:
			phys = modifier_handler.get_modified_value(phys, Modifier.Type.DMG_DEALT)
		if arc > 0:
			arc = modifier_handler.get_modified_value(arc, Modifier.Type.ARCANE_DEALT)
		var modified_damage: int = enemy_ai.target.modifier_handler.get_modified_value(phys + arc, Modifier.Type.DMG_TAKEN)

		if attack_card.go_again:
			new_intent.base_text = "%s GA"
		else:
			new_intent.base_text = "%s"
		new_intent.current_text = new_intent.base_text % modified_damage
		new_intent.icon = preload("res://art/tile_0103.png")
	elif current_action is Weapon:
		var weapon: Weapon = current_action as Weapon
		var phys: int = weapon.attack
		var arc: int = weapon.zap
		if phys > 0:
			phys = modifier_handler.get_modified_value(phys, Modifier.Type.DMG_DEALT)
		if arc > 0:
			arc = modifier_handler.get_modified_value(arc, Modifier.Type.ARCANE_DEALT)
		var modified_damage: int = enemy_ai.target.modifier_handler.get_modified_value(phys + arc, Modifier.Type.DMG_TAKEN)
		if weapon.go_again:
			new_intent.base_text = "%s GA"
		else:
			new_intent.base_text = "%s"
		new_intent.current_text = new_intent.base_text % modified_damage
		new_intent.icon = preload("res://art/tile_0103.png")
	elif current_action is Card and (current_action as Card).type == Card.Type.NAA:
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
		# Weapons can live in plan.actions; they're not in card_ui_map and
		# don't need a hand-color, so skip them in the sanity check.
		for entry in plan.actions:
			if entry is Card and not hand_manager.card_ui_map.has(entry):
				push_warning("[Enemy:%s] plan.actions has '%s' not in card_ui_map" % [stats.character_name, entry.id])
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

func set_current_action(value: Object) -> void:
	if action_sequencer:
		action_sequencer.current_action = value
	update_intent()

func _get_current_action() -> Object:
	return action_sequencer.current_action if action_sequencer else null


# ── Backwards-compat aliases for hand / card_ui_map ──────────────────────────

func _get_hand() -> Array[Card]:
	return hand_manager.hand if hand_manager else []

func _get_card_ui_map() -> Dictionary:
	return hand_manager.card_ui_map if hand_manager else {}


# ── Exhaust pile click + discard-label slide helper ──────────────────────────

const _DISCARD_FLIGHT_DURATION := 0.4

## Open the BattleUI discard_pile_view retargeted to this enemy's exhaust pile.
## Mirrors EnemyResourceUI._on_discard_pressed for the discard counter button.
func _on_exhaust_pile_pressed() -> void:
	if not battle_ui or not stats:
		return
	var enemy_name: String = stats.character_name if stats.character_name else "Enemy"
	battle_ui.show_card_pile(stats.exhaust, "%s Exhaust Pile" % enemy_name)


## Animate an existing card_ui to the EnemyResourceUI discard count label and
## queue_free on landing. Reparents onto BattleUI so the flight isn't bound to
## staged/play-overlay transforms and draws above the hand/sprite.
## Used by EnemyActionSequencer for non-exhausting plays and
## EnemyDefenseSequencer for pitches. Pattern mirrors
## BattleUI._animate_card_to_enemy_label but operates on an existing visual
## instead of spawning a transient.
func animate_card_to_discard_label(card_ui: EnemyCardUI) -> void:
	if not is_instance_valid(card_ui):
		return
	var target_label: Control = enemy_resource_ui.discard_button if enemy_resource_ui else null
	if not target_label or not battle_ui:
		if is_instance_valid(card_ui):
			card_ui.queue_free()
		return

	var gpos := card_ui.global_position
	var gscale := card_ui.scale
	var grot := card_ui.rotation_degrees
	var prev_parent := card_ui.get_parent()
	if prev_parent:
		prev_parent.remove_child(card_ui)
	battle_ui.add_child(card_ui)
	card_ui.global_position = gpos
	card_ui.scale = gscale
	card_ui.rotation_degrees = grot
	card_ui.z_index = 60
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label_center: Vector2 = target_label.global_position + target_label.size / 2.0
	var target_pos: Vector2 = label_center - card_ui.pivot_offset

	var t := card_ui.create_tween()
	t.tween_property(card_ui, "global_position", target_pos, _DISCARD_FLIGHT_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card_ui, "scale", Vector2.ZERO, _DISCARD_FLIGHT_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card_ui, "modulate:a", 0.0, _DISCARD_FLIGHT_DURATION)
	t.tween_callback(func():
		if is_instance_valid(card_ui):
			card_ui.queue_free())
	await t.finished


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
	# Owner-tagged: paired with intent_ui.gd's emits using a distinct instance
	# id so cross-frame mouse_exited(intent) doesn't kill a still-pending
	# sprite-show (or vice versa).
	Events.tooltip_show_for_owner.emit(entries, rect, get_instance_id())

func _on_hover_area_mouse_exited() -> void:
	name_label.hide()
	Events.tooltip_hide_for_owner.emit(get_instance_id())
