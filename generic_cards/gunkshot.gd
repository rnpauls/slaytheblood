extends Card

const TRASH_CARD := preload("res://generic_cards/trash.tres")

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_add_trash
	on_hit.ai_value = 2
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)

func _on_hit_add_trash(target: Node, _args: Array) -> void:
	var effect := CardAddEffect.new()
	effect.card_to_add = TRASH_CARD
	effect.destination = CardAddEffect.Destination.DRAW_PILE_RANDOM
	effect.execute([target])
