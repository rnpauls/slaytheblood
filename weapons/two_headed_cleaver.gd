## Two-Headed Cleaver — Brute's AoE answer. Hits every living enemy and
## gets a flat +N bonus while Enraged. Reshapes the Brute from elite-killer
## into room-clearer.
class_name TwoHeadedCleaverWeapon
extends Weapon

@export var enraged_bonus: int = 2

func activate_weapon(_targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	var temp_attack: int = attack
	if owner and owner.status_handler and owner.status_handler.has_status("enraged"):
		temp_attack += enraged_bonus
	var all_enemies: Array[Node] = _gather_alive_enemies()
	super.activate_weapon(all_enemies, modifiers, temp_attack)


func _gather_alive_enemies() -> Array[Node]:
	var result: Array[Node] = []
	if owner == null or not owner.is_inside_tree():
		return result
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(n) and n is Enemy and n.stats and n.stats.health > 0:
			result.append(n)
	return result
