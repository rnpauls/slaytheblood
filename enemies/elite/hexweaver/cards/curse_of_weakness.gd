extends Card

# Curse of Weakness: applies Exposed (2 turns) to every target. Stacks with
# the Cursed Staff's per-turn Hex Aura tick.

const EXPOSED_STATUS := preload("res://statuses/exposed.tres")


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	for tgt in targets:
		var sh :StatusHandler= tgt.get("status_handler")
		if sh is StatusHandler:
			var dup: ExposedStatus = EXPOSED_STATUS.duplicate()
			dup.duration = 2
			sh.add_status(dup)
