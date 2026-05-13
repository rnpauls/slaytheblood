## Crescent Moon — AoE arc that hits every living enemy and applies Marked.
## Solves Ninja's single-target ceiling and seeds the whole room for the
## Marked-payoff cards (Bullseye, Executioner) in one swing.
class_name CrescentMoonWeapon
extends Weapon

const MARKED_STATUS := preload("res://statuses/marked.tres")

@export var marked_stacks: int = 2

func activate_weapon(_targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	var all_enemies: Array[Node] = _gather_alive_enemies()
	super.activate_weapon(all_enemies, modifiers, custom_attack)
	for enemy in all_enemies:
		if not is_instance_valid(enemy) or enemy.status_handler == null:
			continue
		var mark := MARKED_STATUS.duplicate() as MarkedStatus
		mark.stacks = marked_stacks
		mark.duration = 1
		enemy.status_handler.add_status(mark)


func _gather_alive_enemies() -> Array[Node]:
	var result: Array[Node] = []
	if owner == null or not owner.is_inside_tree():
		return result
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(n) and n is Enemy and n.stats and n.stats.health > 0:
			result.append(n)
	return result
