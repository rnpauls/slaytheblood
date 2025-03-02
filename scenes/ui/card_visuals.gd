class_name CardVisuals
extends Control

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = $Icon
@onready var rarity: TextureRect = $Rarity
@onready var defense: Label = $Defense
@onready var attack: Label = $Attack
@onready var pitch_strip: CanvasModulate = $PitchStrip
@onready var attack_icon: TextureRect = $AttackIcon
@onready var defense_icon: TextureRect = $DefenseIcon


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	cost.text = str(card.cost)
	if card.disable_attack or card.type == Card.Type.BLOCK or card.type == Card.Type.NAA:
		hide_attack()
	else:
		attack.text = str(card.attack)
	if card.disable_defense:
		hide_defense()
	else:
		defense.text = str(card.defense)
	icon.texture = card.icon
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
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
