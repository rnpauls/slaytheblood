class_name DiscardRandomSixEffect
extends Effect

var amount := 1


## Discards `amount` random cards from each target's hand. Returns true iff
## every discarded card had attack > 5 (the "six" filter — used by callers
## that want to gate downstream effects on "all discards were big attacks").
func execute(targets: Array[Node]) -> bool:
	if targets.is_empty():
		return false

	var all_discards_are_six := true
	for target in targets:
		if not (target is Combatant) or target.hand_facade == null:
			continue
		var facade: HandFacade = target.hand_facade
		var sixes := facade.discard_random_filtered(
			func(c: Card) -> bool: return c.attack > 5, amount)
		var remainder := amount - sixes.size()
		if remainder > 0:
			all_discards_are_six = false
			facade.discard_random_filtered(
				func(c: Card) -> bool: return c.attack < 6, remainder)
	return all_discards_are_six
