class_name Hand
extends Control

const CARD_UI_SCENE := preload("res://scenes/card_ui/player_card_ui.tscn")

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

var hovered_card: PlayerCardUI = null 

func _ready() -> void:
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.player_blocks_declared.connect(_on_player_blocks_declared)
	Events.selecting_cards_from_hand.connect(_on_selecting_cards_from_hand)
	Events.finished_selecting_cards_from_hand.connect(_on_finished_selecting_cards_from_hand)
	Events.lock_hand.connect(_on_lock_hand)
	Events.unlock_hand.connect(_on_unlock_hand)
	self.child_order_changed.connect(_on_child_order_changed)

func add_card(card: Card) -> void:
	var new_card_ui := CARD_UI_SCENE.instantiate() as PlayerCardUI
	add_child(new_card_ui)
	
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
	
	new_card_ui.scale = Vector2.ZERO
	new_card_ui.modulate = Color(1, 1, 1, 0)
	
	_arrange_cards()
	
	# Nice draw animation
	var tween := new_card_ui.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_card_ui, "scale", Vector2.ONE * 0.7, 0.25)
	tween.parallel().tween_property(new_card_ui, "modulate", Color.WHITE, 0.25)


func discard_card(card: PlayerCardUI) -> void:
	if card:
		card.queue_free()



func enable_hand() -> void:
	for card: PlayerCardUI in get_children():
		card.disabled = false
		if card.mouse_is_over():
			card.card_state_machine.on_mouse_entered()


func disable_hand() -> void:
	for card: PlayerCardUI in get_children():
		card.disabled = true

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

func _on_selecting_cards_from_hand() -> void:
	is_selecting = true

func _on_finished_selecting_cards_from_hand(_cards: Array[PlayerCardUI]) -> void:
	is_selecting = false
	for handcard in get_children() as Array[PlayerCardUI]:
		handcard.card_state_machine.force_return_to_base_state()

func _on_lock_hand() -> void:
	disable_hand()

func _on_unlock_hand() -> void:
	enable_hand()
