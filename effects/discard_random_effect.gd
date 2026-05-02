class_name DiscardRandomEffect
extends Effect

var amount := 1


func execute(targets: Array[Node]) -> void:
	if targets.is_empty():
		return
		
	#var player_handler := targets[0].get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	#
	#if not player_handler:
		#return
	for target in targets:
		var hand_randomized :Array
		if target is Enemy:
			hand_randomized = target.hand.duplicate() #Array cards
		else:
			hand_randomized = target.hand.get_children().duplicate() #Array cardui
		RNG.array_shuffle(hand_randomized)
		var cards = hand_randomized.slice(0, amount)
		
		for card in cards :
			if target is Enemy:
				card.discard_card()
				target.hand.erase(card)
			else:
				card.discard()
