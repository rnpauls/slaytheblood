class_name CardRenderContainer
extends MarginContainer

@export var card: Card : set = set_card
## When true the card face is hidden and a card-back panel is shown instead.
@export var show_back: bool = false : set = set_show_back

@onready var card_visuals: CardVisuals = %CardVisuals
@onready var viewport_texture: TextureRect = $ViewportTexture
@onready var card_back_panel: Panel = %CardBackPanel
@onready var plan_exclamation: Label = %PlanExclamation

var _plan_stylebox: StyleBoxFlat

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

## Tints the card-back background and toggles the on-hit "!" overlay.
## Used by enemy cards to visualize the AI's turn plan: red=attack, green=NAA,
## blue=pitch, black=not played; show_exclamation=true marks attacks with on-hit.
func set_plan_color(color: Color, show_exclamation: bool) -> void:
	if not is_node_ready():
		await ready
	if _plan_stylebox == null:
		var existing := card_back_panel.get_theme_stylebox("panel")
		_plan_stylebox = existing.duplicate() as StyleBoxFlat
		card_back_panel.add_theme_stylebox_override("panel", _plan_stylebox)
	_plan_stylebox.bg_color = color
	plan_exclamation.visible = show_exclamation
