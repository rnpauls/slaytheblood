## Trash applier with a small physical+arcane hit. Each on-hit fire adds N
## Trash cards into the target's draw pile (preferred way to gunk up enemies
## while still landing damage). Mirrors gunkshot's pattern but adds multiple
## Trash per swing.
extends Card

const TRASH_CARD := preload("res://generic_cards/trash.tres")

@export var trash_per_hit: int = 2


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.id = "cursed_inscription_trash"
	on_hit.custom_func = _on_hit_add_trash
	on_hit.args = [trash_per_hit]
	on_hit.ai_value = trash_per_hit
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_add_trash(target: Node, args: Array) -> void:
	if target == null:
		return
	var qty: int = args[0] if not args.is_empty() else 1
	for i in qty:
		var effect := CardAddEffect.new()
		effect.card_to_add = TRASH_CARD
		effect.destination = CardAddEffect.Destination.DRAW_PILE_RANDOM
		effect.execute([target])
