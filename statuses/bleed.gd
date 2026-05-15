## Bleed: end-of-turn DoT. At the bearer's turn-end, deal `duration` physical
## damage to them (NO_MODIFIER so Empower / Marked / etc. don't double-dip
## with the attack that applied it). DURATION-stacked so multiple bleed
## applications extend the bleed; can_expire so it eventually wears off.
##
## Damage-before-tick: apply_status deals `duration` damage and emits
## status_applied; StatusHandler._on_status_applied then decrements duration
## by 1. So Bleed 3 → 3, 2, 1, gone.
class_name BleedStatus
extends Status


func get_tooltip() -> String:
	return tooltip % duration


func initialize_status(_target: Node) -> void:
	pass


func apply_status(target: Node) -> void:
	if target and duration > 0:
		var dmg := DamageEffect.new()
		dmg.amount = duration
		dmg.damage_kind = Card.DamageKind.PHYSICAL
		dmg.receiver_modifier_type = Modifier.Type.NO_MODIFIER
		dmg.execute([target])
	status_applied.emit(self)
