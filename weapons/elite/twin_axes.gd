class_name TwinAxesWeapon
extends Weapon

const BONUS_DAMAGE := 3
const SOURCE_ID := "twin_axes"

# Wielder gains a permanent +3 DMG_DEALT modifier — integrates automatically
# with the existing intent display and player attack calculations.

func attach_to_combatant(combatant: Combatant) -> void:
	if not combatant or not combatant.modifier_handler:
		return
	var dmg_dealt := combatant.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	if not dmg_dealt:
		return
	var bonus := ModifierValue.create_new_modifier(SOURCE_ID, ModifierValue.Type.FLAT)
	bonus.flat_value = BONUS_DAMAGE
	dmg_dealt.add_new_value(bonus)


func detach_from_combatant(combatant: Combatant) -> void:
	if not combatant or not combatant.modifier_handler:
		return
	var dmg_dealt := combatant.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	if dmg_dealt:
		dmg_dealt.remove_value(SOURCE_ID)
