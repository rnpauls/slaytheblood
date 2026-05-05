## Shows a compact summary of the enemy's hand state: card count icons, arsenal icon,
## pitch resources, and deck count. This is the small HBoxContainer visible in the enemy UI,
## NOT a full CardUI display (see scenes/card_ui/enemy_card_ui.tscn for that).
class_name EnemyHandUI
extends HBoxContainer


@onready var pitch_count: Label = $PitchCount
#@onready var hand_icons: HBoxContainer = $HandIcons
@onready var deck_count: Label = $DeckCount


func update_cards(ai: EnemyAI) -> void:
	pitch_count.text = "%s" % ai.resources
	deck_count.text = "+%s" % ai.enemy.stats.draw_pile.cards.size()
	#var idx = 0
	#for card_icon in hand_icons.get_children():
		#card_icon.visible = (ai.hand.size() > idx)
		#idx += 1
