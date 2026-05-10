## Setup card: gain 1 AP, then load the next attack with a "create N runechants
## on hit" rider. The runechants land on the runeblade themselves (not the
## attack target) and immediately participate in build_attack_packet on the
## next swing — Darken Sky into Runic Spike effectively front-loads the spike.
extends Card

const DARKEN_SKY_CHARGE_STATUS = preload("res://statuses/darken_sky_charge.tres")

@export var charge_stacks: int = 3


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.status_handler == null:
		return
	var charge := DARKEN_SKY_CHARGE_STATUS.duplicate()
	charge.stacks = charge_stacks
	charge.duration = 1
	owner.status_handler.add_status(charge)
