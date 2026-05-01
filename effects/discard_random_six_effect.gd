class_name DiscardRandomSixEffect
extends Effect

var amount := 1


func execute(targets: Array[Node]) -> bool:
	if targets.is_empty():
		return false
		
	var all_discards_are_six: bool

	for target in targets:
		var original_hand :Array
		var hand_only_sixes: Array
		var hand_non_sixes: Array
		#if target is Enemy:
			#original_hand = target.hand.duplicate() #Array cards
			#hand_only_sixes = original_hand.filter(func(card: CardUI): return card.card.attack > 5)
			#hand_non_sixes = original_hand.filter(func(card: CardUI): return card.card.attack < 6)
		#else:
		original_hand = target.hand.get_children().duplicate() #Aeray cardui
		hand_only_sixes = original_hand.filter(func(card: CardUI): return card.card.attack > 5)
		hand_non_sixes = original_hand.filter(func(card: CardUI): return card.card.attack < 6)
		
		var num_non_sixes:= amount - hand_only_sixes.size()
		if num_non_sixes > 0:
			all_discards_are_six = false
			for card in hand_only_sixes:
				card.discard()
			RNG.array_shuffle(hand_non_sixes)
			var cards = hand_non_sixes.slice(0, num_non_sixes)
			for card in cards :
				card.discard()
		else:
			all_discards_are_six = true
			RNG.array_shuffle(hand_only_sixes)
			var cards = hand_only_sixes.slice(0, amount)
			for card in cards :
				card.discard()
	return all_discards_are_six

#func discard_card_from_target(card) -> void:
	##if target:
		##card.discard_card()
		##target.hand.erase(card)
	##else: #player can just call discard
	#card.discard()
