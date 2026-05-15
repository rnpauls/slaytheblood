## Pact of Pain: NAA. Every living allied enemy (caller included) gains
## Empower 2 AND takes 2 damage. The 2-damage tax keeps the buff honest in
## solo fights (Empower 2 for 2 self-damage is a wash); in 3-enemy fights
## it's a powerful all-in.
##
## Damage is dealt via DamageEffect with NO_MODIFIER so existing damage
## modifiers (Phase, Hardshell) don't apply — the cost should always be
## exactly 2 to each ally.
extends Card

const EMPOWERED_STATUS := preload("res://statuses/empowered.tres")
const STACKS := 2
const SELF_DAMAGE := 2


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	for n in owner.get_tree().get_nodes_in_group("enemies"):
		if not (n is Combatant and n.stats and n.stats.health > 0):
			continue
		if n.status_handler:
			var dup: EmpoweredStatus = EMPOWERED_STATUS.duplicate()
			dup.stacks = STACKS
			dup.duration = 1
			n.status_handler.add_status(dup)
		var dmg := DamageEffect.new()
		dmg.amount = SELF_DAMAGE
		dmg.damage_kind = Card.DamageKind.PHYSICAL
		dmg.receiver_modifier_type = Modifier.Type.NO_MODIFIER
		dmg.execute([n])
