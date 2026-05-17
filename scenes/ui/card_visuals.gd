class_name CardVisuals
extends Control

@export var card: Card : set = set_card
## Set by PlayerCardUI from the player's modifier_handler. When null (deck
## view, inventory previews, etc.) refresh_modified_values is a no-op-ish
## passthrough and renders raw card values.
var modifier_handler: ModifierHandler = null
## PlayerCardUI flips this off while the card is "unplayable" so its existing
## red cost-override at player_card_ui._set_playable wins over our modifier
## tint. Default true so non-PlayerCardUI consumers still get cost tinting.
var tint_cost: bool = true

@onready var panel: NinePatchRect = $Panel
@onready var art_panel: TextureRect = %ArtPanel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = %Icon
@onready var filigree: TextureRect = %Filigree
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
@onready var inert_overlay: TextureRect = %InertOverlay

#const FIVE_PIP_4_PITCH_BAR = preload("uid://b7aopbfcwmbtv")
#const FOUR_PIP_4_PITCH_BAR = preload("uid://dnwth2rfebm4q")
const ZERO_PIP_4_PITCH_BAR = preload("uid://biukqdfmbjun2")
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
	# Apply modifier-aware tint on top of the raw values just written, if a
	# handler was assigned before set_card ran. PlayerCardUI also calls this
	# again after assigning modifier_handler post-set_card.
	refresh_modified_values()
	if card.go_again:
		go_again_icon.show()
	else:
		go_again_icon.hide()
	icon.texture = card.icon
	# StyleBoxCache returns one shared StyleBoxFlat per rarity (cached on first use).
	#art_panel.add_theme_stylebox_override("panel", StyleBoxCache.get_rarity_border(art_panel, card.rarity))
	#pitch_strip.modulate = Card.PITCH_COLORS[card.pitch]
	filigree.modulate = Constants.RARITY_COLORS[card.rarity]
	match card.pitch:
		0:
			mana_bar.texture = ZERO_PIP_4_PITCH_BAR
			manabar_underline.modulate = Color.GAINSBORO
		1:
			mana_bar.texture = ONE_PIP_4_PITCH_BAR
			manabar_underline.modulate = Constants.RED_PITCH
		2:
			mana_bar.texture = TWO_PIP_4_PITCH_BAR
			manabar_underline.modulate = Constants.YELLOW_PITCH
		3:
			mana_bar.texture = THREE_PIP_4_PITCH_BAR
			manabar_underline.modulate = Constants.BLUE_PITCH
		#4:
			#pitch_pips.texture = FOUR_PIP_4_PITCH_BAR
		#5:
			#pitch_pips.texture = FIVE_PIP_4_PITCH_BAR

## Recompute the cost label from the current state. Cards with overridden
## get_play_cost() change their displayed cost as runechants / attacks_this_turn
## / discards_this_combat update — PlayerCardUI calls this on stats_changed.
## Routes through refresh_modified_values so the cost tint stays in sync when
## a CARD_COST modifier is active.
func refresh_cost() -> void:
	if card:
		refresh_modified_values()


## Recompute attack / defense / cost labels using the current modifier_handler
## and re-tint each label gold (buff) or crimson (debuff) when the displayed
## value differs from the card's base. Also re-runs the description through
## the modifier-aware keyword formatter so the zap value picks up a color span.
func refresh_modified_values() -> void:
	if not card or not is_node_ready():
		return

	if not (card.disable_attack or card.type == Card.Type.BLOCK or card.type == Card.Type.NAA):
		_apply_value_tint(attack, card.get_attack_value(), card.get_modified_attack(modifier_handler))

	if not card.disable_defense:
		_apply_value_tint(defense, card.defense, card.get_modified_defense(modifier_handler))

	if tint_cost:
		_apply_value_tint(cost, card.get_play_cost(), card.get_modified_cost(modifier_handler))
	else:
		# Cost is being driven by PlayerCardUI's unplayable-red override; just
		# refresh the number without touching font_color.
		cost.text = str(card.get_modified_cost(modifier_handler))

	text_box.text = IconRegistry.expand_icons(
		KeywordRegistry.format_keywords_with_modifiers(card.get_default_tooltip(), modifier_handler))


func _apply_value_tint(label: Label, base: int, modified: int) -> void:
	label.text = str(modified)
	if modified > base:
		label.add_theme_color_override("font_color", Palette.GOLD_HIGHLIGHT)
	elif modified < base:
		label.add_theme_color_override("font_color", Palette.BLOOD_CRIMSON)
	else:
		label.remove_theme_color_override("font_color")

## Toggle the chains-and-padlock overlay that signals "this card is currently
## unplayable" — driven by PlayerCardUI._set_playable. Pile-card consumers
## never call this so decorative copies stay clean.
func set_inert(value: bool) -> void:
	if not is_node_ready():
		await ready
	inert_overlay.visible = value


func hide_attack() ->void:
	attack.hide()
	attack_icon.hide()
	#Should add a pearl?

func hide_defense() ->void:
	defense.hide()
	defense_icon.hide()
	#Should add a pearl?
