## Bloodfire Glaive — HP-fueled arcane glaive. Pure arcane damage bypasses
## block; the per-swing HP cost makes it the glass-cannon Runeblade path
## the class doesn't currently have.
class_name BloodfireGlaiveWeapon
extends Weapon

@export var hp_cost_per_swing: int = 3

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	super.activate_weapon(targets, modifiers, custom_attack)
	if owner and owner.stats:
		owner.stats.health -= hp_cost_per_swing
