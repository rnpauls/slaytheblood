class_name DamageEffect
extends Effect

var amount:= 0
var damage_kind: Card.DamageKind = Card.DamageKind.PHYSICAL
var receiver_modifier_type := Modifier.Type.DMG_TAKEN

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		execute_single_target(target)

func execute_single_target(target: Node) -> void:
	if target is Enemy or target is Player:
		target.take_damage(amount, receiver_modifier_type, damage_kind)
		SFXPlayer.play(sound)
