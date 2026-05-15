## Mark of Pain: Hex Cultist NAA. Hexes the player with Marked 2 (this turn,
## +2 dmg from any hit) AND Vulnerable 1 (permanent, +50% damage taken). The
## Marked dies at end of turn, but the Vulnerable sticks — the player carries
## the cultist's hex for the rest of the fight.
extends Card

const MARKED_STATUS := preload("res://statuses/marked.tres")
const VULNERABLE_STATUS := preload("res://statuses/vulnerable.tres")


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	for t in targets:
		var sh: StatusHandler = t.get("status_handler") if t else null
		if sh == null:
			continue
		var marked: MarkedStatus = MARKED_STATUS.duplicate()
		marked.stacks = 2
		marked.duration = 1
		sh.add_status(marked)
		var vuln: VulnerableStatus = VULNERABLE_STATUS.duplicate()
		sh.add_status(vuln)
