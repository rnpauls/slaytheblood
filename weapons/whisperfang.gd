## Whisperfang — Ninja's combo-finisher dagger. Cheap 1-damage stabs that
## only pay off after the player has built up a combo — once you've
## attacked 3+ times this turn, every Whisperfang swing draws a card.
class_name WhisperfangWeapon
extends Weapon

@export var attacks_required: int = 3

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	super.activate_weapon(targets, modifiers, custom_attack)
	# Check AFTER super: super emits player_attack_declared which increments
	# stats.attacks_this_turn, so the current swing counts toward the
	# threshold. The 3rd attack of the turn is the first to draw.
	if owner is Combatant and owner.stats and owner.stats.attacks_this_turn >= attacks_required:
		if owner.hand_facade:
			owner.hand_facade.draw_cards(1)
