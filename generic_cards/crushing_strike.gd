extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	var dmg := DamageEffect.new()
	dmg.amount = 3
	dmg.damage_kind = Card.DamageKind.PHYSICAL
	dmg.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	on_hit.effect = dmg
	on_hit.ai_value = 4
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)
