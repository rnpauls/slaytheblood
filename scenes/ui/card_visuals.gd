class_name CardVisuals
extends Control

@export var card: Card : set = set_card

@onready var panel: NinePatchRect = $Panel
@onready var art_panel: TextureRect = %ArtPanel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = %Icon
@export var attack: Label
@export var defense: Label
@export var go_again_icon: TextureRect
#@onready var pitch_strip: CanvasModulate = %PitchStrip
#@onready var pitch_pips: TextureRect = %PitchPips
@onready var manabar_underline: TextureRect = %ManabarUnderline
@onready var mana_bar: TextureRect = %ManaBar
@onready var attack_icon: TextureRect = $AttackIcon
@onready var defense_icon: TextureRect = $DefenseIcon
@onready var text_box: RichTextLabel = $TextBox
@onready var type_label: RichTextLabel = $Type
@onready var card_name: RichTextLabel = %Name

#const FIVE_PIP_4_PITCH_BAR = preload("uid://b7aopbfcwmbtv")
#const FOUR_PIP_4_PITCH_BAR = preload("uid://dnwth2rfebm4q")
const ONE_PIP_4_PITCH_BAR = preload("uid://c2f6oqlq3fu1u")#preload("uid://b7u7lguwohkop")
const THREE_PIP_4_PITCH_BAR = preload("uid://dy7gr74myjkmd")#preload("uid://diodbu8p6vfm6")
const TWO_PIP_4_PITCH_BAR = preload("uid://d0llkkmor2k0u")#preload("uid://7g08eoj27y8j")

func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	cost.text = str(card.get_play_cost())
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
	# StyleBoxCache returns one shared StyleBoxFlat per rarity (cached on first use).
	art_panel.add_theme_stylebox_override("panel", StyleBoxCache.get_rarity_border(art_panel, card.rarity))
	#pitch_strip.modulate = Card.PITCH_COLORS[card.pitch]
	match card.pitch:
		1:
			mana_bar.texture = ONE_PIP_4_PITCH_BAR
			manabar_underline.modulate = Color.hex(Constants.RED_PITCH)
		2:
			mana_bar.texture = TWO_PIP_4_PITCH_BAR
			manabar_underline.modulate = Color.hex(Constants.YELLOW_PITCH)
		3:
			mana_bar.texture = THREE_PIP_4_PITCH_BAR
			manabar_underline.modulate = Color.hex(Constants.BLUE_PITCH)
		#4:
			#pitch_pips.texture = FOUR_PIP_4_PITCH_BAR
		#5:
			#pitch_pips.texture = FIVE_PIP_4_PITCH_BAR

## Recompute the cost label from the current state. Cards with overridden
## get_play_cost() change their displayed cost as runechants / attacks_this_turn
## / discards_this_combat update — PlayerCardUI calls this on stats_changed.
func refresh_cost() -> void:
	if card:
		cost.text = str(card.get_play_cost())

func hide_attack() ->void:
	attack.hide()
	attack_icon.hide()
	#Should add a pearl?

func hide_defense() ->void:
	defense.hide()
	defense_icon.hide()
	#Should add a pearl?
