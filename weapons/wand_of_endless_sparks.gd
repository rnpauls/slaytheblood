## Wand of Endless Sparks — pure arcane tempo wand. Generates Runechant
## on every swing so the wielder builds an exponential reserve to pop with
## physical attacks or feed The Conductor.
class_name WandOfEndlessSparksWeapon
extends Weapon

const RUNECHANT_STATUS := preload("res://statuses/runechant.tres")

@export var runechant_per_hit: int = 2

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	super.activate_weapon(targets, modifiers, custom_attack)
	# Seed AFTER super resolves so the new runechants don't immediately pop
	# inside build_attack_packet. Pure-zap weapons (physical == 0) skip the
	# runechant consume anyway, but kept here for consistency with Carver.
	if owner and owner.status_handler:
		var rune := RUNECHANT_STATUS.duplicate()
		rune.stacks = runechant_per_hit
		owner.status_handler.add_status(rune)
