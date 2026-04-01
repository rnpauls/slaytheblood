class_name EnemyCardUI
extends HBoxContainer


@onready var pitch_count: Label = $PitchCount
@onready var arsenal_icon: TextureRect = $ArsenalIcon
@onready var hand_icons: HBoxContainer = $HandIcons
@onready var deck_count: Label = $DeckCount


func update_cards(ai: EnemyAI) -> void:
	pitch_count.text = "%s" % ai.resources
	arsenal_icon.visible = (ai.arsenal != null)
	deck_count.text = "+%s" % ai.enemy.stats.draw_pile.cards.size()
	var idx = 0
	for card_icon in hand_icons.get_children():
		card_icon.visible = (ai.hand.size() > idx)
		idx += 1
		
