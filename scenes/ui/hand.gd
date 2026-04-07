class_name Hand
extends HBoxContainer

const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

@export var player: Player
@export var char_stats: CharacterStats
@export var is_blocking: bool = false
@export var is_selecting: bool = false

func _ready() -> void:
	Events.enemy_attack_declared.connect(_on_enemy_attack_declared)
	Events.player_blocks_declared.connect(_on_player_blocks_declared)
	Events.selecting_cards_from_hand.connect(_on_selecting_cards_from_hand)
	Events.finished_selecting_cards_from_hand.connect(_on_finished_selecting_cards_from_hand)

func add_card(card: Card) -> void:
	var new_card_ui := CARD_UI_SCENE.instantiate() as CardUI
	add_child(new_card_ui)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.parent = self
	new_card_ui.char_stats = char_stats
	new_card_ui.player_modifiers = player.modifier_handler


func discard_card(card: CardUI) -> void:
	card.queue_free()


func enable_hand() -> void:
	for card: CardUI in get_children():
		card.disabled = false
		if card.is_hovered():
			card.card_state_machine.on_mouse_entered()


func disable_hand() -> void:
	for card: CardUI in get_children():
		card.disabled = true


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	child.reparent(self)
	var new_index := clampi(child.original_index, 0, get_child_count())
	move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)

func _on_enemy_attack_declared() -> void:
	is_blocking = true

func _on_player_blocks_declared() -> void:
	is_blocking = false

func _on_selecting_cards_from_hand() -> void:
	is_selecting = true

func _on_finished_selecting_cards_from_hand(_cards: Array[CardUI]) -> void:
	is_selecting = false
	for handcard in get_children() as Array[CardUI]:
		handcard.card_state_machine.force_return_to_base_state()
