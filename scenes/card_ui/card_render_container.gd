class_name CardRenderContainer
extends MarginContainer

@export var card: Card : set = set_card
@onready var card_visuals: CardVisuals = %CardVisuals

func set_card(new_card: Card) -> void:
	if not is_node_ready():
		await ready
		
	card = new_card
	card_visuals.card = card
