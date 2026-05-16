## Warlord's Order: NAA. If the Warlord is alone, they self-buff with Empower
## 2 (so their next attack hits harder). If they have allies, EVERY ally
## (including the Warlord) gains Muscle 1 — the Warlord's signature
## leadership trick that punishes the player for ignoring the grunts.
##
## Conditional behavior is the design point: the Warlord becomes a sustained
## threat alone but a force multiplier in a group.
extends Card

const EMPOWERED_STATUS := preload("res://statuses/empowered.tres")
const MUSCLE_STATUS := preload("res://statuses/muscle.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	var has_ally := false
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if n == owner:
			continue
		if n is Combatant and n.stats and n.stats.health > 0:
			has_ally = true
			break

	if not has_ally:
		# Solo: pile Empower onto self.
		if owner.status_handler:
			var emp: EmpoweredStatus = EMPOWERED_STATUS.duplicate()
			emp.stacks = 4
			emp.duration = 1
			owner.status_handler.add_status(emp)
		return

	# With allies: every living combatant in the enemies group (incl. self)
	# gets a stack of Muscle.
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if not (n is Combatant and n.stats and n.stats.health > 0 and n.status_handler):
			continue
		var dup: MuscleStatus = MUSCLE_STATUS.duplicate()
		dup.stacks = 1
		n.status_handler.add_status(dup)
