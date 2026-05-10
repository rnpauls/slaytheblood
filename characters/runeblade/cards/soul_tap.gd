## Curse payoff: deal arcane scaling with how much Trash you've gunked into
## the room. Sums Trash across every enemy's draw_pile + discard, multiplies
## by `damage_per_trash`, and zaps the chosen target. Late-fight finisher
## for a Curse build that's been seeding Trash all combat.
extends Card

@export var damage_per_trash: int = 2


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		return
	if owner == null or not owner.is_inside_tree():
		return
	var trash_count := 0
	for enemy in owner.get_tree().get_nodes_in_group("enemies"):
		if enemy == null or enemy.stats == null:
			continue
		for pile in [enemy.stats.draw_pile, enemy.stats.discard]:
			if pile == null:
				continue
			for c in pile.cards:
				if c and c.id == "trash":
					trash_count += 1
	var damage := damage_per_trash * trash_count
	if damage > 0:
		do_zap_effect(targets, modifiers, damage)
