## Mark of Pain: Hex Cultist NAA. Hexes the player so attacks against them
## land harder this turn (Marked 2). The cultist itself isn't a heavy hitter
## — Mark of Pain is the setup card for the rest of the encounter (other
## cultists / hexweavers / rats follow up).
extends Card

const MARKED_STATUS := preload("res://statuses/marked.tres")


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	for t in targets:
		var sh: StatusHandler = t.get("status_handler") if t else null
		if sh == null:
			continue
		var dup: MarkedStatus = MARKED_STATUS.duplicate()
		dup.stacks = 2
		dup.duration = 1
		sh.add_status(dup)
