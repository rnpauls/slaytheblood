class_name CatalogTomeWeapon
extends Weapon

const CATALOGER_STATUS := preload("res://statuses/cataloger.tres")
const CATALOGER_SOURCE_ID := "cataloger"

# Wielder gains Cataloger: each START_OF_TURN, block and DMG_DEALT scale with
# the opponent's master-deck size. The Archivist's signature; if the player
# captures it, the same passive turns *enemy* deck sizes against them.


func attach_to_combatant(combatant: Combatant) -> void:
	if not combatant or not combatant.status_handler:
		return
	var status := CATALOGER_STATUS.duplicate() as CatalogerStatus
	combatant.status_handler.add_status(status)


func detach_from_combatant(combatant: Combatant) -> void:
	if not combatant:
		return
	if combatant.status_handler:
		var existing := combatant.status_handler.get_status_by_id("cataloger")
		if existing:
			existing.stacks = 0
	# Status only refreshes the modifier at SOT, so when the weapon leaves we
	# need to scrub its last value or it lingers as a phantom buff.
	if combatant.modifier_handler:
		var dmg_dealt: Modifier = combatant.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
		if dmg_dealt:
			dmg_dealt.remove_value(CATALOGER_SOURCE_ID)
