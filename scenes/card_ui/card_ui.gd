## Base card display + data class.
## Does NOT connect to any Events, does NOT have a state machine.
## PlayerCardUI and EnemyCardUI extend this.
class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_stylebox.tres")
const DRAG_STYLEBOX := preload("res://scenes/card_ui/card_dragging_stylebox.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_stylebox.tres")
const SELECTED_STYLEBOX := preload("res://scenes/card_ui/card_selected_stylebox.tres")
const BURN_SHADER := preload("res://art/shaders/card_burn.gdshader")

const PLAY_EMPHASIS_DURATION := 0.18
const PLAY_EMPHASIS_SCALE_MULT := 1.18
const BURN_DURATION := 0.55

@export var modifier_handler: ModifierHandler : set = _set_modifier_handler
@export var card: Card : set = _set_card
## Accepts both CharacterStats and EnemyStats since both extend Stats.
@export var char_stats: Stats : set = _set_char_stats
@export var hover_scale := 1.0
@export var tween_duration := 0.18

@onready var card_render: CardRenderContainer = $CardRenderContainer

var original_parent: Node
var original_index: int = -1
var original_global_pos: Vector2
var is_hovered := false
var tween: Tween
var targets: Array[Node] = []

signal card_hovered(CardUI)
signal card_unhovered(CardUI)


func animate_to_position(new_position: Vector2, duration: float) -> void:
	_kill_tween()
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)

func animate_to_local_position_and_rotation_and_scale(new_position: Vector2, new_rotation: float, new_scale: float, duration: float) -> void:
	_kill_tween()
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", new_position, duration)
	tween.parallel().tween_property(self, "rotation_degrees", new_rotation, duration)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * new_scale, duration)

## Animate to a global screen position. Used when the card is a Control child of a
## Node2D parent (e.g. EnemyHand), where local `position` is not in the same space
## as the Node2D's world transform.
func animate_to_global_position_and_rotation_and_scale(new_global_position: Vector2, new_rotation: float, new_scale: float, duration: float) -> void:
	_kill_tween()
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_global_position, duration)
	tween.parallel().tween_property(self, "rotation_degrees", new_rotation, duration)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * new_scale, duration)

func return_to_hand() -> void:
	_return_to_original_parent()

func play() -> void:
	if not card:
		return
	if card.unplayable:
		return
	# Hand off to discard BEFORE awaiting effects so the in-flight card_play_finished
	# signal (which adds to the resource pile) sees a matching visual count and skips
	# the auto-spawn. Only non-exhausting player cards route to the visible discard
	# pile; exhausting cards and enemy cards burn up after effects (data side
	# tracking happens in player_handler / enemy_action_sequencer).
	var goes_to_player_pile: bool = not card.exhausts and _is_player_card()
	var pile = _get_discard_pile() if goes_to_player_pile else null
	if pile:
		pile.accept_incoming_visual(self)
		await card.play(self, targets, char_stats, modifier_handler)
	else:
		# Reparent to a sibling of Hand so the card stays visible during effects
		# AND afterwards while it burns. Hand layout no longer includes it.
		_reparent_to_play_overlay()
		await _play_emphasis()
		await card.play(self, targets, char_stats, modifier_handler)
		await _burn_up()
		queue_free()

func discard() -> void:
	if not card:
		return
	var pile = _get_discard_pile() if _is_player_card() else null
	if pile:
		pile.accept_incoming_visual(self)
		card.discard_card()
	else:
		card.discard_card()
		queue_free()

func pitch() -> void:
	if not card:
		return
	var pile = _get_discard_pile() if _is_player_card() else null
	if pile:
		# accept_pitched_visual is a single-card variant: the card slides
		# diagonally from hand to the top-of-stack slot in one continuous arc
		# (no x-snap-then-slide that accept_incoming_visual does for multi-card
		# discards), and tweens scale/rotation smoothly instead of snapping.
		pile.accept_pitched_visual(self)
		card.pitch_card(char_stats)
	else:
		card.pitch_card(char_stats)
		queue_free()

func sink() -> void:
	if not card:
		return
	var pile = _get_draw_pile() if _is_player_card() else null
	if pile:
		pile.accept_incoming_visual(self)
		card.sink_card(char_stats)
	else:
		card.sink_card(char_stats)
		queue_free()

func block() -> void:
	if not card:
		return
	if _is_player_card():
		_reparent_to_play_overlay()
		await _play_emphasis()
		card.block_card([card.owner], modifier_handler)
		await _burn_up()
		queue_free()
	else:
		card.block_card([card.owner], modifier_handler)
		queue_free()


func _is_player_card() -> bool:
	return card and card.owner is Player


# Subclasses override these to hook into hover/click; base no-ops keep the
# scene's signal connections valid when CardUI is instantiated directly
# (e.g. as anonymous backs in CardStackPanel).
func _on_mouse_entered() -> void:
	pass

func _on_mouse_exited() -> void:
	pass

func _on_gui_input(_event: InputEvent) -> void:
	pass


func _get_battle_ui() -> BattleUI:
	# Primary path: every Combatant carries a battle_ui back-ref. Anonymous
	# CardUIs in pile previews (CardStackPanel.reveal_top, etc.) may have
	# card == null or card.owner == null — those callers tolerate a null
	# return, so fall through silently in that case.
	if card and card.owner and card.owner.battle_ui:
		return card.owner.battle_ui
	# Fallback: walk up our own parent chain looking for a BattleUI ancestor.
	# Covers transient CardUIs that were never assigned an owner (e.g.
	# face-down placeholders in pile panels).
	var node: Node = get_parent()
	while node:
		if node is BattleUI:
			return node
		node = node.get_parent()
	return null


# Returns CardStackPanel; the type annotation is dropped to break the
# class_name dependency cycle with card_stack_panel.gd (which references CardUI).
func _get_draw_pile():
	var bu := _get_battle_ui()
	return bu.draw_pile if bu else null


func _get_discard_pile():
	var bu := _get_battle_ui()
	return bu.discard_pile if bu else null

func get_active_enemy_modifiers() -> ModifierHandler:
	if targets.is_empty() or targets.size() > 1 or targets[0] is not Enemy:
		return null
	return targets[0].modifier_handler

func mouse_is_over() -> bool:
	var rect := Rect2(Vector2.ZERO, self.size)
	return rect.has_point(get_local_mouse_position())

func request_tooltip() -> void:
	if not card:
		return
	var enemy_modifiers := get_active_enemy_modifiers()
	var updated_tooltip := card.get_updated_tooltip(modifier_handler, enemy_modifiers)

	# Cards already show their own name + body on the face when hovered, so
	# only emit boxes for keywords referenced in the description.
	var entries: Array[TooltipData] = KeywordRegistry.build_tooltip_chain(updated_tooltip)
	if entries.is_empty():
		return

	# Card-anchored: tooltip sits next to the card. TooltipLayer flips
	# horizontally + vertically against viewport edges as needed.
	Events.tooltip_show_requested.emit(entries, Rect2(global_position, size))

func select() -> void:
	pass

func deselect() -> void:
	pass

func _return_to_original_parent() -> void:
	if not is_inside_tree(): return
	reparent_requested.emit(self)
	z_index = 0
	scale = Vector2.ONE * 0.7

func _set_card(value: Card) -> void:
	if not value:
		return
	if not is_node_ready():
		await ready
	card = value
	card_render.card = card as Card

func _set_char_stats(value: Stats) -> void:
	char_stats = value
	if char_stats and not char_stats.stats_changed.is_connected(_on_char_stats_changed):
		char_stats.stats_changed.connect(_on_char_stats_changed)

## Base no-op setter — subclasses (PlayerCardUI) override to also connect the
## modifier_handler's modifiers_changed signal and propagate to card_visuals.
func _set_modifier_handler(value: ModifierHandler) -> void:
	modifier_handler = value

func _on_char_stats_changed() -> void:
	pass

func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)

func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)

func _kill_tween() -> void:
	if tween and tween.is_running():
		tween.kill()


## Reparent the card to a sibling of Hand so it stays visible (and on top of
## the hand) during effects + burn. Preserves global transform.
func _reparent_to_play_overlay() -> void:
	var bu := _get_battle_ui()
	if not bu:
		# No overlay available — leave parent alone; card just stays where it is.
		return
	var gpos := global_position
	var grot := rotation_degrees
	var gscale := scale
	var prev := get_parent()
	if prev == bu:
		return
	if prev:
		prev.remove_child(self)
	bu.add_child(self)
	# Last child draws on top among CanvasLayer children.
	bu.move_child(self, bu.get_child_count() - 1)
	global_position = gpos
	rotation_degrees = grot
	scale = gscale
	z_index = 50


## Brief scale pop + brightness flash to punctuate a card being played. Always
## resolves at the original transform so the subsequent effects don't fight a
## modified scale.
func _play_emphasis() -> void:
	_kill_tween()
	var base_scale := scale
	var pop_scale := base_scale * PLAY_EMPHASIS_SCALE_MULT
	var half := PLAY_EMPHASIS_DURATION * 0.5
	tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", pop_scale, half).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1.6, 1.5, 1.2, 1.0), half).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale, half).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, half).set_ease(Tween.EASE_IN)
	await tween.finished


## Burn-up dissolve: applies the burn shader to the rendered card face and
## tweens its `progress` uniform from 0 to 1, then resolves. Caller queue_frees.
## The shader material is created per-call so cards in flight don't share
## state, and so we don't need to clean up the original (unset) material.
func _burn_up() -> void:
	if not card_render or not card_render.viewport_texture:
		return
	var mat := ShaderMaterial.new()
	mat.shader = BURN_SHADER
	mat.set_shader_parameter("progress", 0.0)
	# The card face renders into a SubViewport and is shown by ViewportTexture
	# (a TextureRect). Putting the shader on that single TextureRect burns the
	# whole face uniformly without needing use_parent_material on every child.
	card_render.viewport_texture.material = mat
	# Hide playability glow during burn so it doesn't outline the dissolving card.
	card_render.set_glow(false)
	_kill_tween()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("progress", v),
		0.0, 1.0, BURN_DURATION
	)
	await tween.finished
