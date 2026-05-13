class_name Hand
extends Control

const CARD_UI_SCENE = preload("res://scenes/card_ui/player_card_ui.tscn")
#const CARD_UI_SCENE = preload("uid://c8jhetww6oc2a")
#const CARD_UI_SCENE = preload("uid://c8jhetww6oc2a")

# ── Fanout settings ─────────────────────────────────────────────────────
@export var max_width := 1200.0
@export var width_mult_hovered := 1.1
@export var width_per_card := 75
@export var height_offset := 120.0
@export var max_rotation_deg := 25.0

## Gentle upward arc (create a new Curve in the editor and make it look like a very flat U)
@export var position_curve: Curve
## Steeper at the edges for natural tilt
@export var rotation_curve: Curve

@export var player: Player
@export var char_stats: CharacterStats
@export var is_blocking: bool = false
@export var is_selecting: bool = false
var selection_limit: int = 0
var is_enabled: bool = false

var hovered_card: PlayerCardUI = null

func _ready() -> void:
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.player_blocks_declared.connect(_on_player_blocks_declared)
	Events.selecting_cards_from_hand.connect(_on_selecting_cards_from_hand)
	Events.finished_selecting_cards_from_hand.connect(_on_finished_selecting_cards_from_hand)
	Events.lock_hand.connect(_on_lock_hand)
	Events.unlock_hand.connect(_on_unlock_hand)
	self.child_order_changed.connect(_on_child_order_changed)

## Add a card to the hand. If `source_visual` is provided (typically a card-back
## released from the draw pile), the new hand card starts at that visual's
## position and flips face-up after landing in the hand slot. Otherwise, falls
## back to the original scale-from-zero fade-in.
func add_card(card: Card, source_visual: CardUI = null) -> void:
	var new_card_ui := CARD_UI_SCENE.instantiate() as PlayerCardUI

	new_card_ui.original_parent = self
	new_card_ui.original_index = get_child_count() - 1   # ← its position in the hand

	new_card_ui.card = card
	new_card_ui.char_stats = char_stats
	new_card_ui.modifier_handler = player.modifier_handler

	new_card_ui.pivot_offset = new_card_ui.size / 2

	# Connect signals
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card_hovered.connect(_on_card_hovered)
	new_card_ui.card_unhovered.connect(_on_card_unhovered)

	if source_visual and is_instance_valid(source_visual):
		add_child(new_card_ui)
		# Match the draw pile's top card so the flight starts seamlessly from there.
		new_card_ui.global_position = source_visual.global_position
		new_card_ui.scale = source_visual.scale
		new_card_ui.rotation_degrees = source_visual.rotation_degrees
		new_card_ui.card_render.show_back = true
		source_visual.queue_free()
	else:
		new_card_ui.scale = Vector2.ZERO
		new_card_ui.modulate = Color(1, 1, 1, 0)
		add_child(new_card_ui)

	new_card_ui.disabled = not is_enabled

	_arrange_cards()

	if source_visual:
		# X-squish flip from back to face during the flight to the hand. Driven
		# in parallel with the position/rotation/scale tween from _arrange_cards;
		# the flip targets card_render.scale (a child) instead of new_card_ui.scale
		# so the two tweens don't fight on the same property.
		var t := new_card_ui.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(new_card_ui.card_render, "scale:x", 0.0, Constants.TWEEN_CARD_FLIP)
		t.tween_callback(func():
			if is_instance_valid(new_card_ui) and new_card_ui.card_render:
				new_card_ui.card_render.show_back = false)
		t.tween_property(new_card_ui.card_render, "scale:x", 1.0, Constants.TWEEN_CARD_FLIP)
	else:
		# Original scale-up fade-in for non-pile spawns.
		var tween := new_card_ui.create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(new_card_ui, "scale", Vector2.ONE * 0.7, Constants.TWEEN_HAND_ENTRY)
		tween.parallel().tween_property(new_card_ui, "modulate", Color.WHITE, Constants.TWEEN_HAND_ENTRY)


func enable_hand() -> void:
	is_enabled = true
	print_debug("[Hand] enable_hand (cards=%d)" % get_child_count())
	for child in get_children():
		if child is PlayerCardUI:
			var card := child as PlayerCardUI
			card.disabled = false
			if card.mouse_is_over():
				card.card_state_machine.on_mouse_entered()


func disable_hand() -> void:
	is_enabled = false
	print_debug("[Hand] disable_hand (cards=%d)" % get_child_count())
	for child in get_children():
		if child is PlayerCardUI:
			(child as PlayerCardUI).disabled = true

func _arrange_cards() -> void:
	var cards: Array[PlayerCardUI] = []
	for child in get_children():
		if child is PlayerCardUI:
			cards.append(child)

	if cards.is_empty():
		return

	var count := cards.size()
	var base_width := count*width_per_card
	if hovered_card : base_width *= width_mult_hovered
	base_width = min(base_width, max_width)

	# Get the logical index the hovered card *should* have
	var logical_hovered_index := -1
	if hovered_card != null:
		logical_hovered_index = hovered_card.original_index
		if logical_hovered_index < 0 or logical_hovered_index >= get_child_count() + 1:
			logical_hovered_index = cards.find(hovered_card)

	for i in count:
		var effective_t: float
		var card := cards[i]
		if card == hovered_card:
				continue
		if count == 1:
			effective_t = 0.5
		else:
			var t: float = float(i) / max(1, count - 1)

			# === ASYMMETRIC SPREADING around logical hovered position ===
			effective_t = t
			if hovered_card != null and logical_hovered_index != -1:
				var dist_from_hover := absf(i - logical_hovered_index) / float(max(1, count))
				var push := (1.0 - dist_from_hover) * 0.1

				if i < logical_hovered_index:
					effective_t = t - push
				elif i > logical_hovered_index:
					effective_t = t + push

				effective_t = clampf(effective_t, 0.0, 1.0)

		# Position & rotation
		var x: float = lerp(-base_width / 2, base_width / 2, effective_t) + size.x/2 - card.size.x/2
		var y := _sample_position_curve(effective_t) * height_offset * -1
		var rot := _sample_rotation_curve(effective_t) * max_rotation_deg - max_rotation_deg / 2
		card.animate_to_local_position_and_rotation_and_scale(Vector2(x, y), rot, 0.7, 0.25)

func _sample_position_curve(t: float) -> float:
	if position_curve:
		return position_curve.sample(t)
	# fallback gentle parabola
	return -4.0 * (t - 0.5) * (t - 0.5) + 1.0


func _sample_rotation_curve(t: float) -> float:
	if rotation_curve:
		return rotation_curve.sample(t)
	return t  # linear fallback works fine

## Resting local-x for a card at the given child index in the hovered (wider)
## fan. The hover state snaps x to this so a newly-hovered card doesn't stay at
## the pushed-aside x it had as a neighbor of the previously-hovered card.
func get_natural_hovered_x_for_index(index: int, card_size_x: float) -> float:
	var count := 0
	for child in get_children():
		if child is PlayerCardUI:
			count += 1
	var base_width := float(count) * width_per_card * width_mult_hovered
	base_width = min(base_width, max_width)
	var t: float = 0.5 if count <= 1 else float(index) / max(1, count - 1)
	return lerp(-base_width / 2, base_width / 2, t) + size.x / 2 - card_size_x / 2

#Set card's original positions for use when returning to hand
func _on_child_order_changed() -> void:
	if not is_node_ready():
		return
	var cards: Array[PlayerCardUI] = []
	for child in get_children():
		if child is PlayerCardUI:
			cards.append(child)
	if not hovered_card in cards:
		hovered_card = null

	if cards.is_empty():
		return

	var count := cards.size()
	var base_width := count*width_per_card
	if hovered_card : base_width *= width_mult_hovered
	base_width = min(base_width, max_width)
	for i in count:
		var card := cards[i]
		var t: float = float(i) / max(1, count - 1)
		var x: float = lerp(-base_width / 2, base_width / 2, t) + size.x/2 - card.size.x/2
		var y := _sample_position_curve(t) * height_offset * -1
		card.original_global_pos = global_position + Vector2(x,y)
	call_deferred("_update_all_original_indices")
	call_deferred("_arrange_cards")

func _on_card_ui_reparent_requested(child: PlayerCardUI) -> void:
	if not is_instance_valid(child) or child.get_parent() == self:
		return
	
	child.disabled = true
	child.reparent(self)
	
	# Use the saved original_index, but clamp safely
	var target_index := clampi(child.original_index, 0, get_child_count())
	move_child(child, target_index)
	
	# Update the index of EVERY card after reparent (safety net)
	_update_all_original_indices()
	
	child.set_deferred("disabled", false)
	call_deferred("_arrange_cards")

func _update_all_original_indices() -> void:
	for i in get_child_count():
		var card := get_child(i) as PlayerCardUI
		if card:
			card.original_index = i


func _on_card_hovered(card: PlayerCardUI) -> void:
	if hovered_card == card:
		print("hand onhovered but already hovered")
		return
	hovered_card = card

	var count := get_child_count()
	var pitch := 1.0 if count <= 1 else lerpf(0.85, 1.15, card.original_index / float(count - 1))
	SFXRegistry.play(&"HOVER_CARD", pitch)

	call_deferred("_arrange_cards")   # spread everything out


func _on_card_unhovered(card: PlayerCardUI) -> void:
	if hovered_card == card:
		hovered_card = null
		for kid in get_children():
			if kid.is_hovered: return
		call_deferred("_arrange_cards")   # return to normal spacing
	else:
		print_debug("hand unhovered but card is diff")

func _on_enemy_attack_declared() -> void:
	is_blocking = true

func _on_player_blocks_declared() -> void:
	is_blocking = false

func _on_selecting_cards_from_hand(limit: int) -> void:
	is_selecting = true
	selection_limit = limit

func _on_finished_selecting_cards_from_hand(_cards: Array[CardUI]) -> void:
	is_selecting = false
	selection_limit = 0
	for child in get_children():
		if child is PlayerCardUI:
			(child as PlayerCardUI).card_state_machine.force_return_to_base_state()

func count_selected_cards() -> int:
	var count := 0
	for handcard in get_children():
		if handcard is PlayerCardUI and handcard.selected:
			count += 1
	return count

func _on_lock_hand() -> void:
	disable_hand()

func _on_unlock_hand() -> void:
	enable_hand()
