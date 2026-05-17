class_name BattleUI
extends CanvasLayer

const _ANNOUNCEMENT_HOLD := 0.7

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var hand: Hand = $Hand
@onready var mana_ui: ManaUI = $ManaUI
@onready var action_points_ui: ActionPointsUI = $ActionPointsUI
@onready var end_turn_button: Button = %EndTurnButton
@onready var block_button: TextureButton = %BlockButton
@onready var draw_pile: CardStackPanel = %DrawPile
@onready var discard_pile: CardStackPanel = %DiscardPile
@onready var exhaust_button: TextureButton = %ExhaustButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
@onready var exhaust_pile_view: CardPileView = %ExhaustPileView
@onready var choice_screen: ColorRect = %ChoiceScreen
@onready var choice_screen_label: RichTextLabel = %ChoiceScreenLabel
@onready var turn_announcer_label: Label = %TurnAnnouncerLabel
@onready var turn_announcer_bar: ColorRect = %TurnAnnouncerBar

var waiting_for_battle_start:= true
var num_cards_to_choose: int = 0
var min_cards_to_choose: int = 0
#var is_blocking:= false
var _exhaust_button_tween: Tween

# Player-turn counter for the turn-announcement overlay. Increments on each
# PLAYER_SOT; the matching ENEMY_SOT reuses the same number ("Player Turn N"
# then "Enemy Turn N"). Reset implicitly by BattleUI being re-instantiated
# per battle.
var current_turn: int = 0
var _turn_announcer_tween: Tween

# Back-ref to the owning Battle, set via bind_battle(). Used to read the
# current acting enemy off enemy_handler.acting_enemies for per-enemy
# turn announcements.
var _battle: Battle

# Slide-in/out state for the End Turn and Block buttons. Each has its own
# home (resting position captured on _ready) and offscreen (home + width +
# margin past the right edge). Only one button is visible at a time, so a
# single shared tween reference is enough.
var _end_turn_button_home: Vector2
var _end_turn_button_offscreen: Vector2
var _block_button_home: Vector2
var _block_button_offscreen: Vector2
var _mode_button_tween: Tween
var _block_button_hover_tween: Tween
const _END_TURN_BUTTON_OFFSCREEN_MARGIN := 40.0
# BlockButton sits further inset from the viewport's right edge than EndTurnButton,
# so width + standard margin leaves part of it on screen — bump it out an extra 20.
const _BLOCK_BUTTON_EXTRA_OFFSCREEN := 20.0
const _BLOCK_BUTTON_HOVER_TINT := Color(1.5, 1.5, 0.5)

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.player_initial_hand_drawn.connect(_on_player_initial_hand_drawn)
	Events.player_action_phase_started.connect(_on_player_action_phase_started)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	block_button.pressed.connect(_on_block_button_pressed)
	block_button.mouse_entered.connect(_on_block_button_mouse_entered)
	block_button.mouse_exited.connect(_on_block_button_mouse_exited)
	draw_pile.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", true))
	discard_pile.pressed.connect(_on_discard_pile_pressed)
	exhaust_button.pressed.connect(exhaust_pile_view.show_current_view.bind("Exhaust Pile"))
	exhaust_button.pivot_offset = exhaust_button.size / 2.0
	exhaust_button.mouse_entered.connect(_on_exhaust_button_mouse_entered)
	exhaust_button.mouse_exited.connect(_on_exhaust_button_mouse_exited)
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.enemy_phase_ended.connect(_on_enemy_phase_ended)
	Events.top_card_reveal_requested.connect(_on_top_card_reveal_requested)
	Events.card_add_animation_requested.connect(_on_card_add_animation_requested)
	TooltipHelper.attach(draw_pile, "Draw Pile", "Cards left to draw this combat. Click to view. Reshuffled from your discard when empty.")
	TooltipHelper.attach(discard_pile, "Discard Pile", "Cards you've used this combat. Click to view. Returns to your draw pile when it empties.")
	TooltipHelper.attach(exhaust_button, "Exhaust Pile", "Cards removed for the rest of this combat. Click to view.")
	# Defer one frame so the buttons have resolved their anchored sizes before
	# we snapshot home / compute offscreen targets. Without the defer, .size is
	# (0,0) before the first layout pass.
	call_deferred("_init_mode_button_positions")


## Battle hands us a self-reference after _setup_turn_state_machine() so we
## can listen for PLAYER_SOT / ENEMY_SOT to drive the centered turn-
## announcement label AND read the current acting enemy off
## battle.enemy_handler. Called once per combat, after the SM has already
## entered COMBAT_START (so we deliberately miss that initial emit — we only
## announce player / enemy turn boundaries, not setup).
func bind_battle(battle: Battle) -> void:
	if not battle or not battle.turn_state_machine:
		return
	_battle = battle
	battle.turn_state_machine.state_changed.connect(_on_turn_state_changed)


func _init_mode_button_positions() -> void:
	_end_turn_button_home = end_turn_button.position
	_end_turn_button_offscreen = _end_turn_button_home + Vector2(
		end_turn_button.size.x + _END_TURN_BUTTON_OFFSCREEN_MARGIN, 0)
	_block_button_home = block_button.position
	_block_button_offscreen = _block_button_home + Vector2(
		block_button.size.x + _END_TURN_BUTTON_OFFSCREEN_MARGIN + _BLOCK_BUTTON_EXTRA_OFFSCREEN, 0)
	# Battle starts with both buttons offscreen — the END TURN one slides on in
	# _on_player_initial_hand_drawn so the first turn feels like the rest.
	end_turn_button.position = _end_turn_button_offscreen
	block_button.position = _block_button_offscreen

func initialize_card_pile_ui() ->void:
	draw_pile.card_pile = char_stats.draw_pile
	draw_pile_view.card_pile = char_stats.draw_pile
	discard_pile.card_pile = char_stats.discard
	discard_pile_view.card_pile = char_stats.discard
	exhaust_pile_view.card_pile = char_stats.exhaust


## The player's discard pile click rebinds the view to the player's discard
## first — this is the trigger that resets the view if it was retargeted to
## an enemy's discard via show_card_pile().
func _on_discard_pile_pressed() -> void:
	discard_pile_view.card_pile = char_stats.discard
	discard_pile_view.show_current_view("Discard Pile")


## Open the discard-pile viewer retargeted to an arbitrary CardPile (used by
## the EnemyResourceUI trash button to show an enemy's discard). The next click
## on the player's discard pile re-binds back to char_stats.discard.
func show_card_pile(pile: CardPile, title: String) -> void:
	discard_pile_view.card_pile = pile
	discard_pile_view.show_current_view(title)

## Prompt the player to pick `num_cards` from their hand. Awaits user input
## and returns the chosen CardUIs. Optional prompt_text overrides the default
## "Choose N cards" label so card scripts can show a verb-specific prompt
## (e.g. "Sink a card", "Exhaust a card"). Optional min_cards lowers the
## confirm-gate floor (defaults to num_cards = strict equality); pass 0 to
## let the player confirm with nothing selected. Most callers should go
## through PlayerHandFacade.prompt_choose_cards rather than calling this
## directly.
func choose_cards_in_hand(num_cards: int, prompt_text: String = "", min_cards: int = -1) -> Array[CardUI]:
	num_cards_to_choose = num_cards
	min_cards_to_choose = clampi(min_cards if min_cards >= 0 else num_cards, 0, num_cards)
	choice_screen_label.text = prompt_text if not prompt_text.is_empty() else "Choose %s cards" % num_cards_to_choose
	choice_screen.show()
	Events.selecting_cards_from_hand.emit(num_cards_to_choose)
	var selected_cards: Array[CardUI] = await Events.finished_selecting_cards_from_hand
	return selected_cards

func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value 
	mana_ui.char_stats = char_stats
	action_points_ui.char_stats = char_stats
	hand.char_stats = char_stats

## EOT cleanup completed and the hand is back at full size. The button is
## already offscreen at this point (slid off when the player clicked End
## Turn), so just keep it disabled. Also emit player_turn_ended for status
## effects (intimidated/poison_tip/empowered) that hook into "the player's
## turn just ended".
func _on_player_hand_drawn() -> void:
	print_debug("[EndBtn] disable from _on_player_hand_drawn (post-EOT)")
	end_turn_button.disabled = true
	Events.player_turn_ended.emit()

func _on_player_initial_hand_drawn() -> void:
	print_debug("[EndBtn] enable+slide-on from _on_player_initial_hand_drawn")
	waiting_for_battle_start = false
	# The SM skips PLAYER_SOT on the first turn (see combat_start_state.gd —
	# the SOT cascade already ran inside player_handler.start_battle()), so
	# the state_changed listener won't announce PLAYER TURN 1. Seed it here
	# manually; subsequent turns are handled by _on_turn_state_changed.
	current_turn = 1
	_show_turn_announcement("PLAYER TURN %d" % current_turn)
	_set_end_turn_button_mode_end_turn()
	end_turn_button.disabled = false
	_slide_active_button_onscreen()

func _on_player_action_phase_started() -> void:
	if waiting_for_battle_start:
		print_debug("[EndBtn] _on_player_action_phase_started skipped (waiting_for_battle_start)")
	else:
		print_debug("[EndBtn] enable from _on_player_action_phase_started")
		end_turn_button.disabled = false

func _on_end_turn_button_pressed() -> void:
	print_debug("[EndBtn] disable from _on_end_turn_button_pressed")
	end_turn_button.disabled = true
	_slide_active_button_offscreen()
	Events.player_end_phase_started.emit()


func _on_block_button_pressed() -> void:
	print_debug("[BlockBtn] disable from _on_block_button_pressed")
	SFXRegistry.play(&"CLICK_BUTTON")
	block_button.disabled = true
	# Instant snap (placeholder until the block-click impact frame is built).
	# Mode swap happens later when the next enemy attack declares or the enemy
	# phase ends — at which point the right button slides back on.
	block_button.position = _block_button_offscreen
	Events.player_blocks_declared.emit()


func _on_block_button_mouse_entered() -> void:
	SFXRegistry.play(&"HOVER_UI")
	if _block_button_hover_tween and _block_button_hover_tween.is_running():
		_block_button_hover_tween.kill()
	_block_button_hover_tween = block_button.create_tween() \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_block_button_hover_tween.tween_property(
		block_button, "modulate", _BLOCK_BUTTON_HOVER_TINT, Constants.TWEEN_UI_HOVER)


func _on_block_button_mouse_exited() -> void:
	if _block_button_hover_tween and _block_button_hover_tween.is_running():
		_block_button_hover_tween.kill()
	_block_button_hover_tween = block_button.create_tween() \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_block_button_hover_tween.tween_property(
		block_button, "modulate", Color.WHITE, Constants.TWEEN_UI_HOVER)


func _on_enemy_attack_declared() -> void:
	print_debug("[BlockBtn] enable+slide-on from _on_enemy_attack_declared")
	_set_end_turn_button_mode_block()
	block_button.disabled = false
	_slide_active_button_onscreen()


func _on_enemy_phase_ended() -> void:
	print_debug("[EndBtn] enable+slide-on from _on_enemy_phase_ended")
	_set_end_turn_button_mode_end_turn()
	end_turn_button.disabled = false
	_slide_active_button_onscreen()


# ── End-turn / Block button helpers ────────────────────────────────────────

func _set_end_turn_button_mode_end_turn() -> void:
	block_button.visible = false
	end_turn_button.visible = true


func _set_end_turn_button_mode_block() -> void:
	end_turn_button.visible = false
	block_button.visible = true
	# Reset any leftover hover tint from a previous BLOCK round so the button
	# always reappears at full opacity / no tint.
	if _block_button_hover_tween and _block_button_hover_tween.is_running():
		_block_button_hover_tween.kill()
	block_button.modulate = Color.WHITE


func _active_mode_button() -> Control:
	return block_button if block_button.visible else end_turn_button


func _active_mode_button_home() -> Vector2:
	return _block_button_home if block_button.visible else _end_turn_button_home


func _active_mode_button_offscreen() -> Vector2:
	return _block_button_offscreen if block_button.visible else _end_turn_button_offscreen


func _slide_active_button_onscreen() -> void:
	var btn := _active_mode_button()
	var home := _active_mode_button_home()
	var offscreen := _active_mode_button_offscreen()
	if _mode_button_tween and _mode_button_tween.is_running():
		_mode_button_tween.kill()
	# If somehow already onscreen, start from offscreen so the motion reads.
	if btn.position == home:
		btn.position = offscreen
	_mode_button_tween = btn.create_tween() \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_mode_button_tween.tween_property(
		btn, "position", home, Constants.TWEEN_END_TURN_BUTTON)


func _slide_active_button_offscreen() -> void:
	var btn := _active_mode_button()
	var offscreen := _active_mode_button_offscreen()
	if _mode_button_tween and _mode_button_tween.is_running():
		_mode_button_tween.kill()
	_mode_button_tween = btn.create_tween() \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_mode_button_tween.tween_property(
		btn, "position", offscreen, Constants.TWEEN_END_TURN_BUTTON)


# ── Turn-announcement overlay ──────────────────────────────────────────────

## Driven by TurnStateMachine.state_changed. Only PLAYER_SOT / ENEMY_SOT
## announce; COMBAT_START, *_EOT, *_ACTING, VICTORY/DEFEAT/STALEMATE are
## silent. Turn number increments on PLAYER_SOT and the matching ENEMY_SOT
## reuses it (Slay-the-Spire round convention).
func _on_turn_state_changed(state: int) -> void:
	match state:
		TurnState.State.PLAYER_SOT:
			current_turn += 1
			_show_turn_announcement("PLAYER TURN %d" % current_turn)
		TurnState.State.ENEMY_SOT:
			var enemy := _current_acting_enemy()
			if enemy:
				_show_turn_announcement("%s TURN %d" % [
					enemy.stats.character_name.to_upper(), current_turn])


# Reads the head of the enemy queue — set by EnemyHandler.start_turn() and
# popped per-enemy as ENEMY_EOT advances. Empty / invalid means there's no
# enemy whose turn is starting, so callers should skip the announcement.
func _current_acting_enemy() -> Enemy:
	if not _battle or not _battle.enemy_handler:
		return null
	var queue: Array[Enemy] = _battle.enemy_handler.acting_enemies
	if queue.is_empty():
		return null
	var enemy: Enemy = queue[0]
	return enemy if is_instance_valid(enemy) else null


func _show_turn_announcement(text: String) -> void:
	if not turn_announcer_label or not turn_announcer_bar:
		return
	if _turn_announcer_tween and _turn_announcer_tween.is_running():
		_turn_announcer_tween.kill()
	turn_announcer_label.text = text
	turn_announcer_label.modulate.a = 0.0
	turn_announcer_label.scale = Vector2.ONE * 0.8
	turn_announcer_bar.modulate.a = 0.0
	turn_announcer_bar.scale = Vector2(1, 0)
	_turn_announcer_tween = turn_announcer_label.create_tween()
	# Step 1 — open: bar shutters vertically + fades in; label fades + pops in.
	_turn_announcer_tween.tween_property(
		turn_announcer_bar, "scale:y", 1.0, Constants.TWEEN_FADE
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_turn_announcer_tween.parallel().tween_property(
		turn_announcer_bar, "modulate:a", 1.0, Constants.TWEEN_FADE
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_turn_announcer_tween.parallel().tween_property(
		turn_announcer_label, "modulate:a", 1.0, Constants.TWEEN_FADE
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_turn_announcer_tween.parallel().tween_property(
		turn_announcer_label, "scale", Vector2.ONE, Constants.TWEEN_FADE
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Step 2 — hold.
	_turn_announcer_tween.tween_interval(_ANNOUNCEMENT_HOLD)
	# Step 3 — close: bar collapses + fades out; label fades out.
	_turn_announcer_tween.tween_property(
		turn_announcer_label, "modulate:a", 0.0, Constants.TWEEN_FADE
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_turn_announcer_tween.parallel().tween_property(
		turn_announcer_bar, "modulate:a", 0.0, Constants.TWEEN_FADE
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_turn_announcer_tween.parallel().tween_property(
		turn_announcer_bar, "scale:y", 0.0, Constants.TWEEN_FADE
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	# Signals ENEMY_SOT (and anyone else waiting) that the announcement is fully
	# off-screen and the next phase can begin.
	_turn_announcer_tween.tween_callback(Events.turn_announcement_finished.emit)


func _on_exhaust_button_mouse_entered() -> void:
	if _exhaust_button_tween and _exhaust_button_tween.is_running():
		_exhaust_button_tween.kill()
	_exhaust_button_tween = exhaust_button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_exhaust_button_tween.tween_property(exhaust_button, "scale", Vector2.ONE * 1.15, Constants.TWEEN_UI_HOVER)


func _on_exhaust_button_mouse_exited() -> void:
	if _exhaust_button_tween and _exhaust_button_tween.is_running():
		_exhaust_button_tween.kill()
	_exhaust_button_tween = exhaust_button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_exhaust_button_tween.tween_property(exhaust_button, "scale", Vector2.ONE, Constants.TWEEN_UI_HOVER)


func _on_confirm_button_pressed() -> void:
	var chosen_cards: Array[CardUI]
	for tempcard in hand.get_children():
		if tempcard.selected:
			chosen_cards.append(tempcard)
	if chosen_cards.size() >= min_cards_to_choose and chosen_cards.size() <= num_cards_to_choose:
		Events.finished_selecting_cards_from_hand.emit(chosen_cards)
		choice_screen.hide()


## Routes top-card-reveal requests to the right visual handler. Player owners
## use the on-screen draw pile; enemy owners (no visual pile yet) use a
## transient overlay near screen center. Either path eventually emits
## `Events.top_card_reveal_finished` so the caller can resume.
func _on_top_card_reveal_requested(card: Card, source_owner: Node) -> void:
	if source_owner is Player and draw_pile:
		draw_pile.reveal_top(card)
	else:
		_transient_top_card_reveal(card)


const _TRANSIENT_REVEAL_CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

func _transient_top_card_reveal(card: Card) -> void:
	var visual := _TRANSIENT_REVEAL_CARD_UI_SCENE.instantiate() as CardUI
	add_child(visual)
	visual.card_render.show_back = true
	visual.card = card
	var viewport_size := get_viewport().get_visible_rect().size
	visual.global_position = (viewport_size - CardStackPanel.CARD_SIZE_UNSCALED) / 2.0
	visual.scale = Vector2.ONE
	visual.z_index = 100

	var t := visual.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(Constants.TWEEN_CARD_FLIP)
	t.tween_property(visual, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP)
	t.tween_callback(func():
		if is_instance_valid(visual) and visual.card_render:
			visual.card_render.show_back = false)
	t.tween_property(visual, "scale:x", 1.0, Constants.TWEEN_CARD_FLIP)
	t.tween_interval(0.6)
	t.tween_property(visual, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP)
	t.tween_callback(func():
		if is_instance_valid(visual) and visual.card_render:
			visual.card_render.show_back = true)
	t.tween_property(visual, "scale:x", 1.0, Constants.TWEEN_CARD_FLIP)
	t.tween_callback(func():
		if is_instance_valid(visual):
			visual.queue_free()
		Events.top_card_reveal_finished.emit())


## Routes a CardAddEffect animation request to the right visual handler. The
## emit happens BEFORE the resource pile is mutated; for player draw/discard
## destinations, the called CardStackPanel.animate_card_in does the visual
## handoff (parent CardUI in, mark _pitched_in_flight) so the immediately-
## following size_changed handler skips its auto-spawn. For HAND, we hold a
## temp visual at center then trigger the existing hand.add_card flow. For
## enemy targets there's no pile UI to hand off to — we just play a fly-to-
## label flair and free the visual.
func _on_card_add_animation_requested(card: Card, target: Node, destination: int) -> void:
	if not card or not target:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var source_pos: Vector2 = (viewport_size - CardStackPanel.CARD_SIZE_UNSCALED) / 2.0

	if target is Player:
		match destination:
			CardAddEffect.Destination.HAND:
				if hand:
					_animate_card_to_hand(card, source_pos)
			CardAddEffect.Destination.DISCARD_PILE:
				if discard_pile:
					discard_pile.animate_card_in(card, source_pos)
			_:
				if draw_pile:
					draw_pile.animate_card_in(card, source_pos)
	elif target is Enemy:
		_animate_card_to_enemy_label(card, target as Enemy, destination, source_pos)


func _animate_card_to_hand(card: Card, source_pos: Vector2) -> void:
	var temp := _TRANSIENT_REVEAL_CARD_UI_SCENE.instantiate() as CardUI
	add_child(temp)
	temp.card = card
	if temp.card_render:
		temp.card_render.show_back = false
	temp.global_position = source_pos
	temp.scale = Vector2.ONE
	temp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp.z_index = 100
	# Hold at center so the player can read the card, then trigger the existing
	# draw-style entry: hand.add_card consumes the temp visual (queue_free'd
	# inside add_card) and starts a new PlayerCardUI at the temp's transform.
	var t := temp.create_tween()
	t.tween_interval(1.0)
	t.tween_callback(func():
		if is_instance_valid(temp) and is_instance_valid(hand):
			hand.add_card(card, temp))


func _animate_card_to_enemy_label(card: Card, enemy: Enemy, destination: int, source_pos: Vector2) -> void:
	if not enemy or not enemy.enemy_resource_ui:
		return
	var resource_ui := enemy.enemy_resource_ui
	var target_label: Control = (
		resource_ui.discard_button
		if destination == CardAddEffect.Destination.DISCARD_PILE
		else resource_ui.deck_icon
	)
	if not target_label:
		return
	var visual := _TRANSIENT_REVEAL_CARD_UI_SCENE.instantiate() as CardUI
	add_child(visual)
	visual.card = card
	if visual.card_render:
		visual.card_render.show_back = false
	visual.global_position = source_pos
	visual.scale = Vector2.ONE
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.z_index = 100
	var label_center: Vector2 = target_label.global_position + target_label.size / 2.0
	var target_pos: Vector2 = label_center - visual.pivot_offset

	var t := visual.create_tween()
	t.tween_interval(1.0)
	t.tween_property(visual, "global_position", target_pos, 0.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "scale", Vector2.ZERO, 0.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "modulate:a", 0.0, 0.8)
	t.tween_callback(func():
		if is_instance_valid(visual):
			visual.queue_free())
