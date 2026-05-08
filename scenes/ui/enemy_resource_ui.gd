## Compact HBox showing the enemy's draw pile size, current pitch resources,
## and discard pile size with a button to view the discard pile contents.
class_name EnemyResourceUI
extends HBoxContainer


@onready var deck_count: Label = $DeckCount
@onready var resource_count: Label = $ResourceCount
@onready var discard_button: TextureButton = $DiscardButton
@onready var discard_count: Label = $DiscardCount

var _ai: EnemyAI


func _ready() -> void:
	discard_button.pressed.connect(_on_discard_pressed)


func update_display(ai: EnemyAI) -> void:
	_ai = ai
	deck_count.text = "%s" % ai.enemy.stats.draw_pile.cards.size()
	resource_count.text = "%s" % ai.resources
	discard_count.text = "%s" % ai.enemy.stats.discard.cards.size()


func _on_discard_pressed() -> void:
	if not _ai or not _ai.enemy or not _ai.enemy.stats:
		return
	var battle_ui := get_tree().get_first_node_in_group("ui_layer") as BattleUI
	if not battle_ui:
		return
	var enemy_name: String = _ai.enemy.stats.character_name if _ai.enemy.stats.character_name else "Enemy"
	battle_ui.show_card_pile(_ai.enemy.stats.discard, "%s Discard Pile" % enemy_name)
