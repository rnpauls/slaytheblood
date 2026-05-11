class_name HexsigilCrownEquipment
extends Equipment


func initialize_equipment(owner_node) -> void:
	super.initialize_equipment(owner_node)
	if not Events.combatant_attacked.is_connected(_on_combatant_attacked):
		Events.combatant_attacked.connect(_on_combatant_attacked)


func deactivate_equipment(_owner_node: Node) -> void:
	if Events.combatant_attacked.is_connected(_on_combatant_attacked):
		Events.combatant_attacked.disconnect(_on_combatant_attacked)


func _on_combatant_attacked(victim: Node, attacker: Node, _attempted: int, _damage_dealt: int) -> void:
	if victim != owner:
		return
	if not used_this_attack:
		return
	if attacker is Combatant and attacker.hand_facade:
		attacker.hand_facade.discard_random(1)
