## Zap N: deal N arcane damage to a target. Fires through the existing
## DamageEffect pipeline with damage_kind = ARCANE, so it bypasses block and
## is mitigated by mana spend in Stats.take_damage. No on-hit triggers and no
## defend_attack declaration — Zap is a clean arcane bolt, not an attack.
class_name ZapEffect
extends DamageEffect

func _init() -> void:
	damage_kind = Card.DamageKind.ARCANE
