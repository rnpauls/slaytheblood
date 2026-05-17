class_name CardAddEffect
extends Effect

enum Destination { DRAW_PILE_RANDOM, DRAW_PILE_TOP, DRAW_PILE_BOTTOM, DISCARD_PILE, HAND }

var card_to_add: Card
var destination: Destination = Destination.DRAW_PILE_RANDOM


func execute(targets: Array[Node]) -> void:
	if not card_to_add:
		return
	SFXRegistry.play_stream(sound)
	for target in targets:
		if not target or not target.stats:
			continue
		var new_card := card_to_add.duplicate() as Card
		# Emit BEFORE mutating the resource pile so the BattleUI listener can
		# do the visual handoff (parent the flying CardUI into the target panel)
		# ahead of the size_changed handler — otherwise we'd see a duplicate
		# auto-spawned visual fly up from below the pile.
		Events.card_add_animation_requested.emit(new_card, target, destination)
		match destination:
			Destination.DRAW_PILE_RANDOM:
				_insert_random(target.stats.draw_pile, new_card)
			Destination.DRAW_PILE_TOP:
				_insert_at(target.stats.draw_pile, new_card, 0)
			Destination.DRAW_PILE_BOTTOM:
				if target.stats.draw_pile:
					target.stats.draw_pile.add_card(new_card)
			Destination.DISCARD_PILE:
				if target.stats.discard:
					target.stats.discard.add_card(new_card)
			Destination.HAND:
				_add_to_hand(target, new_card)


func _insert_random(pile: CardPile, card: Card) -> void:
	if not pile:
		return
	var idx := randi() % (pile.cards.size() + 1)
	_insert_at(pile, card, idx)


func _insert_at(pile: CardPile, card: Card, idx: int) -> void:
	if not pile:
		return
	pile.cards.insert(idx, card)
	pile.card_pile_size_changed.emit(pile.cards.size())


func _add_to_hand(target: Node, card: Card) -> void:
	# Both Enemy and Player expose add_card_to_hand on the Combatant; the
	# implementations diverge (Enemy routes through hand_manager, Player
	# through PlayerHandler.hand) but the call site is symmetric.
	if target is Combatant and target.has_method("add_card_to_hand"):
		target.add_card_to_hand(card)
