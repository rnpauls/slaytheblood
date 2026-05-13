## The Conductor — on every landed hit, doubles the wielder's current
## Runechant stacks via an OnHit effect. Turns Runechant into per-swing
## payoff fuel: 1 → 2 → 4 → 8 across a single combo turn.
class_name TheConductorWeapon
extends Weapon

const RUNECHANT_STATUS := preload("res://statuses/runechant.tres")
const ON_HIT_ID := "the_conductor_double_runechant"

func attach_to_combatant(_combatant: Combatant) -> void:
	var on_hit := OnHit.new()
	on_hit.id = ON_HIT_ID
	on_hit.custom_func = _on_hit_double_runechant
	on_hits = [on_hit]


func detach_from_combatant(_combatant: Combatant) -> void:
	on_hits = []


# Fires from AttackDamageEffect / ZapEffect when this weapon's swing lands
# damage. ai_value is the live Runechant stack count at hit time — we read
# it directly off the status to stay accurate even if other effects
# changed the pile between activate_weapon and the hit resolving.
func _on_hit_double_runechant(_target: Node, _args: Array) -> void:
	if owner == null or owner.status_handler == null:
		return
	var rune := owner.status_handler.get_status_by_id("runechant") as RunechantStatus
	if rune == null or rune.stacks <= 0:
		return
	var add := RUNECHANT_STATUS.duplicate() as RunechantStatus
	add.stacks = rune.stacks
	owner.status_handler.add_status(add)
