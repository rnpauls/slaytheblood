## Berserker's Bite — scales with missing HP, churns the hand toward 6+ atk
## cards via sixloot. The lower the wielder drops, the harder it hits and
## the faster the heavy hitters cycle into the hand.
class_name BerserkersBiteWeapon
extends Weapon

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	var temp_attack: int = 0
	if owner and owner.stats:
		var missing: int = maxi(0, owner.stats.max_health - owner.stats.health)
		temp_attack = missing / 4
	super.activate_weapon(targets, modifiers, temp_attack)
	# Sixloot 1 — discard a random card, preferring 6+ atk. Result ignored:
	# Berserker's Bite churns the hand whether or not the discard was a six.
	sixloot(owner, 1)


func get_display_attack() -> int:
	if owner == null or owner.stats == null:
		return 0
	var missing: int = maxi(0, owner.stats.max_health - owner.stats.health)
	return missing / 4
