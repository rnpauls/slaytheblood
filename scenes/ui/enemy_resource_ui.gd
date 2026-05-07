## Compact HBox showing the enemy's draw pile size and current pitch resources.
class_name EnemyResourceUI
extends HBoxContainer


@onready var deck_count: Label = $DeckCount
@onready var resource_count: Label = $ResourceCount


func update_display(ai: EnemyAI) -> void:
	deck_count.text = "%s" % ai.enemy.stats.draw_pile.cards.size()
	resource_count.text = "%s" % ai.resources
