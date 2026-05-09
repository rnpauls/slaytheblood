class_name TowerShieldWeapon
extends Weapon

const BULWARK_STATUS := preload("res://statuses/bulwark.tres")
const BULWARK_STACKS := 5

# Wielder gains Bulwark (+5 block at SOT) for the duration of combat. Tower
# Shield is the Bulwark Knight's signature; if the player captures it they
# can also swing it actively for a defensive surge.

func attach_to_combatant(combatant: Combatant) -> void:
	if not combatant or not combatant.status_handler:
		return
	var status := BULWARK_STATUS.duplicate() as BulwarkStatus
	status.stacks = BULWARK_STACKS
	combatant.status_handler.add_status(status)


func detach_from_combatant(combatant: Combatant) -> void:
	if not combatant or not combatant.status_handler:
		return
	var existing := combatant.status_handler.get_status_by_id("bulwark")
	if existing:
		existing.stacks = maxi(0, existing.stacks - BULWARK_STACKS)


# Player swing: standard hit + bonus block to self.
func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	super.activate_weapon(targets, modifiers, custom_attack)
	if owner:
		owner.stats.block += 8
