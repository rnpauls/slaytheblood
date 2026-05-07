class_name CardDrawEffect
extends Effect

var cards_to_draw := 1


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if target is Combatant and target.hand_facade:
			target.hand_facade.draw_cards(cards_to_draw)
