## Echo Blade — if the player has already played at least one Attack card
## this turn, the swing lands twice. Bonus hit doesn't re-pay cost / AP
## / weapon_used_up bookkeeping — only the damage repeats.
class_name EchoBladeWeapon
extends Weapon

func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	# Check BEFORE super: super emits player_attack_declared which increments
	# stats.attacks_this_turn — without the early capture, this weapon's own
	# swing would count and Echo Blade would trigger on the first activation.
	var should_echo: bool = owner != null and owner.stats != null and owner.stats.attacks_this_turn > 0
	super.activate_weapon(targets, modifiers, custom_attack)
	if should_echo:
		do_stock_attack_damage_effect(targets, modifiers, custom_attack)
