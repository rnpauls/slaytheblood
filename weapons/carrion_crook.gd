## Carrion Crook — death-rattle weapon. Doesn't do anything special on hit;
## the payoff is detach_from_combatant, which Enemy._on_death calls before
## the bearer is freed. Every surviving allied enemy in the encounter gets
## permanent Muscle 3 — turning the bearer's death into a power-up for the
## rest of the fight.
##
## Implementation: Muscle (not Empowered) because Muscle stacks are
## permanent for the battle, matching the "rest-of-fight buff" intent.
class_name CarrionCrookWeapon
extends Weapon

const MUSCLE_GAIN := 3
const MUSCLE_STATUS := preload("res://statuses/muscle.tres")


func attach_to_combatant(_combatant: Combatant) -> void:
	# No on-hit; the value is in the on-death buff via detach.
	on_hits = []


func detach_from_combatant(combatant: Combatant) -> void:
	on_hits = []
	if combatant == null or not is_instance_valid(combatant) or not combatant.is_inside_tree():
		return
	# Only buff if the bearer is actually dying (HP 0). Skip if the weapon is
	# being unequipped for some other reason (player capture, future swap).
	if combatant.stats and combatant.stats.health > 0:
		return
	var tree := combatant.get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("enemies"):
		if n == combatant:
			continue
		if not (n is Combatant and n.stats and n.stats.health > 0 and n.status_handler):
			continue
		var dup: MuscleStatus = MUSCLE_STATUS.duplicate()
		dup.stacks = MUSCLE_GAIN
		n.status_handler.add_status(dup)
