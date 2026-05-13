extends Card

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var on_hit := OnHit.new()
	on_hit.custom_func = _on_hit_snatch
	on_hit.ai_value = 4
	on_hits.append(on_hit)
	do_stock_attack_damage_effect(targets, modifiers)


func _on_hit_snatch(atk_target: Node, _args: Array) -> void:
	if not (atk_target is Combatant):
		return
	var victim := atk_target as Combatant
	if victim.hand_facade == null:
		return
	var hand := victim.hand_facade.get_hand()
	if hand.is_empty():
		return

	var original: Card = hand[randi() % hand.size()]

	# Remove the original from the victim's hand with no pile destination —
	# it's stolen, not discarded or exhausted. Player cards only target enemies,
	# so the Enemy branch is the only realistic case; the facade has no
	# "remove without destination" method, so reach into hand_manager directly.
	if victim is Enemy:
		(victim as Enemy).hand_manager.remove_card(original)

	var stolen := original.duplicate() as Card
	stolen.owner = owner

	if owner and owner.has_method("add_card_to_hand"):
		owner.add_card_to_hand(stolen)
