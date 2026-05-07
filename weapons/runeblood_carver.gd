## Runeblood Carver — the Runeblade's starter blade. Plain 1-damage swing,
## but every swing seeds a runechant on the wielder, building arcane charge
## for the next attack.
extends Weapon

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	super.activate_weapon(targets, modifiers, custom_attack)
	# Seed AFTER super resolves — otherwise the new runechant would pop on
	# the same swing inside build_attack_packet, which defeats the point.
	if owner and owner.status_handler:
		var rune := RUNECHANT_STATUS.duplicate()
		rune.stacks = 1
		owner.status_handler.add_status(rune)
