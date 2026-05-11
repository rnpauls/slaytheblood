## Hex: dump 3 Trash into the target's draw pile and apply Exposed (target takes
## 50% more damage for N turns). The Trash sits in their deck as unplayable
## filler, the Exposed amplifies whatever lands in the meantime.
extends Card

const TRASH_CARD := preload("res://generic_cards/trash.tres")
const EXPOSED_STATUS := preload("res://statuses/exposed.tres")

@export var trash_count: int = 3
@export var exposed_duration: int = 2


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		return
	var target_node := targets[0]
	for i in trash_count:
		var effect := CardAddEffect.new()
		effect.card_to_add = TRASH_CARD
		effect.destination = CardAddEffect.Destination.DRAW_PILE_RANDOM
		effect.execute([target_node])
	if target_node.status_handler:
		var exposed := EXPOSED_STATUS.duplicate()
		exposed.duration = exposed_duration
		target_node.status_handler.add_status(exposed)
