class_name CursedStaffWeapon
extends Weapon

const HEX_AURA_STATUS := preload("res://statuses/hex_aura.tres")

# Wielder gains Hex Aura: at the start of every turn, applies one stack of
# Exposed (1-turn) to every opposing combatant. Hexweaver's signature; if
# captured by the player, gives them a permanent debuff aura on enemies.

func attach_to_combatant(combatant: Combatant) -> void:
	if not combatant or not combatant.status_handler:
		return
	var status := HEX_AURA_STATUS.duplicate() as HexAuraStatus
	combatant.status_handler.add_status(status)


func detach_from_combatant(combatant: Combatant) -> void:
	if not combatant or not combatant.status_handler:
		return
	var existing := combatant.status_handler.get_status_by_id("hex_aura")
	if existing:
		existing.stacks = 0
