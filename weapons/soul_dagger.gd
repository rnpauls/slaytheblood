## Soul Dagger — Ninja's spirit-link blade. Each card sunk this turn powers
## the next swing by +1. Rewards sink-heavy draws and combos with any redraw
## chain that loops cards through the deck.
class_name SoulDaggerWeapon
extends Weapon

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, _custom_atk: int = attack) -> void:
	var bonus: int = 0
	if owner and owner.stats:
		bonus = owner.stats.sinks_this_turn
	super.activate_weapon(targets, modifiers, attack + bonus)
