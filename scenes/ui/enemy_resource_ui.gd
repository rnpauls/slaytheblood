## Compact HBox showing the enemy's draw pile size, current pitch resources,
## and discard pile size with a button to view the discard pile contents.
class_name EnemyResourceUI
extends HBoxContainer


@onready var deck_count: Label = $DeckCount
@onready var resource_count: Label = $ResourceCount
@onready var discard_button: TextureButton = $DiscardButton
@onready var discard_count: Label = $DiscardCount
@onready var deck_icon: TextureRect = $DeckIcon
@onready var resource_icon: TextureRect = $ResourceIcon

var _ai: EnemyAI


func _ready() -> void:
	discard_button.pressed.connect(_on_discard_pressed)
	TooltipHelper.attach(deck_icon, "Enemy Draw Pile", "Cards left in the enemy's draw pile.")
	TooltipHelper.attach(resource_icon, "Enemy Resource", "The enemy's current resource pool.")
	TooltipHelper.attach(discard_button, "Enemy Discard Pile", "Cards the enemy has used this combat. Click to view.")


func update_display(ai: EnemyAI) -> void:
	if _ai and _ai != ai:
		var prev_draw := _ai.enemy.stats.draw_pile
		var prev_discard := _ai.enemy.stats.discard
		if prev_draw.card_pile_size_changed.is_connected(_on_draw_pile_size_changed):
			prev_draw.card_pile_size_changed.disconnect(_on_draw_pile_size_changed)
		if prev_discard.card_pile_size_changed.is_connected(_on_discard_size_changed):
			prev_discard.card_pile_size_changed.disconnect(_on_discard_size_changed)
	_ai = ai
	var draw_pile := ai.enemy.stats.draw_pile
	var discard := ai.enemy.stats.discard
	if not draw_pile.card_pile_size_changed.is_connected(_on_draw_pile_size_changed):
		draw_pile.card_pile_size_changed.connect(_on_draw_pile_size_changed)
	if not discard.card_pile_size_changed.is_connected(_on_discard_size_changed):
		discard.card_pile_size_changed.connect(_on_discard_size_changed)
	deck_count.text = "%s" % draw_pile.cards.size()
	resource_count.text = "%s" % ai.resources
	discard_count.text = "%s" % discard.cards.size()


func _on_draw_pile_size_changed(new_size: int) -> void:
	deck_count.text = "%s" % new_size


func _on_discard_size_changed(new_size: int) -> void:
	discard_count.text = "%s" % new_size


func _on_discard_pressed() -> void:
	if not _ai or not _ai.enemy or not _ai.enemy.stats:
		return
	var battle_ui := _ai.enemy.battle_ui
	if not battle_ui:
		return
	var enemy_name: String = _ai.enemy.stats.character_name if _ai.enemy.stats.character_name else "Enemy"
	battle_ui.show_card_pile(_ai.enemy.stats.discard, "%s Discard Pile" % enemy_name)
