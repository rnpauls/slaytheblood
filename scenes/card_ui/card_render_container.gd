class_name CardRenderContainer
extends MarginContainer

@export var card: Card : set = set_card
## When true the card face is hidden and a card-back panel is shown instead.
@export var show_back: bool = false : set = set_show_back

@onready var card_visuals: CardVisuals = %CardVisuals
@onready var viewport_texture: TextureRect = $ViewportTexture
@onready var card_back_panel: Panel = $CardBackPanel

func set_card(new_card: Card) -> void:
	if not is_node_ready():
		await ready
	card = new_card
	card_visuals.card = card

func set_show_back(value: bool) -> void:
	show_back = value
	if not is_node_ready():
		await ready
	viewport_texture.visible = not show_back
	card_back_panel.visible = show_back
