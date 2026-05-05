class_name CardVisuals
extends Control

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var art_panel: Panel = %ArtPanel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = %Icon
@export var attack: Label
@export var defense: Label
@export var go_again_icon: TextureRect
@onready var pitch_strip: CanvasModulate = $PitchStrip
@onready var attack_icon: TextureRect = $AttackIcon
@onready var defense_icon: TextureRect = $DefenseIcon
@onready var text_box: RichTextLabel = $TextBox
@onready var type_label: RichTextLabel = $Type
@onready var card_name: RichTextLabel = $Name


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	cost.text = str(card.cost)
	text_box.text = IconRegistry.expand_icons(KeywordRegistry.format_keywords(card.get_default_tooltip()))
	type_label.text = str(card.TypeString.keys()[card.type])
	card_name.text = card.id.capitalize()
	if card.disable_attack or card.type == Card.Type.BLOCK or card.type == Card.Type.NAA:
		hide_attack()
	else:
		attack.text = str(card.attack)
	if card.disable_defense:
		hide_defense()
	else:
		defense.text = str(card.defense)
	if card.go_again:
		go_again_icon.show()
	else:
		go_again_icon.hide()
	icon.texture = card.icon
	#panel.add_theme_color_override("border_color",Card.RARITY_COLORS[card.rarity])
	# Shitty panel mod that creates a new stylebox for every single card
	var stylebox: StyleBoxFlat = art_panel.get_theme_stylebox("panel").duplicate()
	stylebox.border_color = Card.RARITY_COLORS[card.rarity] 
	art_panel.add_theme_stylebox_override("panel", stylebox)
	pitch_strip.modulate = Card.PITCH_COLORS[card.pitch]
	#pitch_strip.ColorRect2.modulate = Card.PITCH_COLORS[card.pitch]
	#pitch_strip.ColorRect3.modulate = Card.PITCH_COLORS[card.pitch]

func hide_attack() ->void:
	attack.hide()
	attack_icon.hide()
	#Should add a pearl?

func hide_defense() ->void:
	defense.hide()
	defense_icon.hide()
	#Should add a pearl?
