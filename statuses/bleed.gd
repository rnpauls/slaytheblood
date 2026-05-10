## Bleed: end-of-turn DoT. At the bearer's turn-end, deal `stacks` physical
## damage to them (NO_MODIFIER so Empower / Marked / etc. don't double-dip
## with the attack that applied it). INTENSITY-stacked so multiple Slashing
## Cuts pile on; can_expire so the bleed eventually wears off.
##
## Type = END_OF_TURN — StatusHandler.apply_statuses_by_type runs the
## tick, then status_applied decrements duration via
## StatusHandler._on_status_applied. Fires from
## enemy_end_of_turn_state.gd:31 and player_handler.gd:334.
class_name BleedStatus
extends Status


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(_target: Node) -> void:
	pass


func apply_status(target: Node) -> void:
	if target and stacks > 0:
		var dmg := DamageEffect.new()
		dmg.amount = stacks
		dmg.damage_kind = Card.DamageKind.PHYSICAL
		dmg.receiver_modifier_type = Modifier.Type.NO_MODIFIER
		dmg.execute([target])
	status_applied.emit(self)
