class_name CardPileView
extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

signal card_selected(card: Card)

@export var card_pile: CardPile
@export var selection_mode: bool = false

@onready var title: Label = %Title
@onready var cards: GridContainer = %Cards
@onready var back_button: Button = %BackButton
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup

func _ready() -> void:
	back_button.pressed.connect(hide)
	# Hiding the view doesn't reliably fire mouse_exited on the CardMenuUI
	# children, so clear any tooltip whenever the view becomes hidden.
	visibility_changed.connect(_on_visibility_changed)

	for card: Node in cards.get_children():
		card.queue_free()

	card_tooltip_popup.hide_tooltip()


func _on_visibility_changed() -> void:
	if not visible:
		Events.tooltip_hide_requested.emit()

func _input(event:InputEvent) ->void:
	if event.is_action_pressed("ui_cancel"):
		if card_tooltip_popup.visible:
			card_tooltip_popup.hide_tooltip()
		else:
			hide()

func show_current_view(new_title: String, sorted: bool = false) ->void:
	for card: Node in cards.get_children():
		card.queue_free()

	card_tooltip_popup.hide_tooltip()
	title.text = new_title
	_update_view.call_deferred(sorted)

func _update_view(sorted: bool) ->void:
	if not card_pile:
		return

	var all_cards := card_pile.cards.duplicate()
	if sorted:
		all_cards.sort_custom(_compare_by_color_then_name)
	
	for card: Card in all_cards:
		var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		cards.add_child(new_card)
		new_card.card = card
		if selection_mode:
			new_card.tooltip_requested.connect(_on_card_selected)
		else:
			#new_card.tooltip_requested.connect(card_tooltip_popup.show_tooltip)
			pass

	show()


func _on_card_selected(card: Card) -> void:
	card_selected.emit(card)
	hide()


static func _compare_by_color_then_name(a: Card, b: Card) -> bool:
	# pitch 0 = no color; push it to the end of the list, after blue (pitch 3).
	var a_key: int = a.pitch if a.pitch > 0 else 99
	var b_key: int = b.pitch if b.pitch > 0 else 99
	if a_key != b_key:
		return a_key < b_key
	return a.id < b.id
