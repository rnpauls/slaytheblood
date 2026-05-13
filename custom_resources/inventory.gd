class_name Inventory
extends Resource

#signal inventory_changed()

@export var weapons: Array[Weapon] = []
@export var equips: Array[Equipment] = []

func empty() -> bool:
	return weapons.is_empty() and equips.is_empty()

func add_weapon(weapon: Weapon) -> void:
	weapons.append(weapon)
	#inventory_changed.emit()

func remove_weapon(weapon: Weapon) -> void:
	weapons.erase(weapon)
	#inventory_changed.emit()

func add_equipment(equipment: Equipment) -> void:
	equips.append(equipment)
	#inventory_changed.emit()

func remove_equipment(equipment: Equipment) -> void:
	equips.erase(equipment)
	#inventory_changed.emit()

func clear() -> void:
	weapons.clear()
	equips.clear()
	#card_pile_size_changed.emit(cards.size())

func _to_string() -> String:
	var _strings: PackedStringArray = []
	for i in range(weapons.size()):
		_strings.append("W%s: %s" % [i+1, weapons[i].id])
	for i in range(equips.size()):
		_strings.append("E%s: %s" % [i+1, equips[i].id])
	return "\n".join(_strings)

func has_weapon(id: String) -> bool:
	for tmp_wep in weapons as Array[Weapon]:
		if tmp_wep and (tmp_wep.id == id) and is_instance_valid(tmp_wep):
			return true
	return false

func has_equipment(id: String) -> bool:
	for tmp_eq in equips as Array[Equipment]:
		if tmp_eq and (tmp_eq.id == id) and is_instance_valid(tmp_eq):
			return true
	return false
