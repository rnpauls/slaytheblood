## Heartblood Maul — cost-0 / go-again hammer that burns 4 HP per swing.
## Pushes the HP-trade theme to its limit: free, repeatable, devastating,
## but the wielder bleeds out almost as fast as the target.
class_name HeartbloodMaulWeapon
extends Weapon

@export var hp_cost_per_swing: int = 4

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	super.activate_weapon(targets, modifiers, custom_attack)
	if owner and owner.stats:
		owner.stats.health -= hp_cost_per_swing
