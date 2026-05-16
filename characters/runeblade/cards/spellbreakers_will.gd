## Big zap that also debuffs the target with Exposed. The Exposed lands after
## the zap so the card's own damage matches the printed 8; the Exposed sets up
## subsequent hits (incoming and outgoing — Exposed is on DMG_TAKEN).
extends Card

const EXPOSED_STATUS = preload("res://statuses/exposed.tres")


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	do_zap_effect(targets, modifiers, zap)
	for t in targets:
		if t == null or t.status_handler == null:
			continue
		var expo := EXPOSED_STATUS.duplicate()
		expo.stacks = 2
		expo.duration = 2
		t.status_handler.add_status(expo)
