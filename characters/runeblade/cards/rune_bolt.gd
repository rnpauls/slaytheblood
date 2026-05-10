## Dynamic-cost spell. Each runechant on the runeblade reduces this card's
## cost by 1 (clamped at 0); the runechants themselves are NOT consumed by
## Rune Bolt — they remain to power up the next attack. Rewards stacking
## a runechant pile and then firing off cheap, repeatable Rune Bolts while
## the pile carries forward.
extends Card


func get_play_cost() -> int:
	var discount := 0
	if owner and owner.status_handler:
		var rune := owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			discount = rune.stacks
	return maxi(0, cost - discount)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_zap_effect(targets, modifiers, zap)
