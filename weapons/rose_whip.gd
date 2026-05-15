## Rose Whip — Ninja bleed amplifier. On hit inflicts Bleed 1; after the
## swing (even on a fully-blocked miss) doubles the target's current Bleed
## duration. Because on_hit fires inside super.activate_weapon, a clean hit
## on a zero-bleed target ends at Bleed 2: the fresh 1 is included in the double.
class_name RoseWhipWeapon
extends Weapon

const BLEED_STATUS := preload("res://statuses/bleed.tres")
const ON_HIT_ID := "rose_whip_inflict_bleed"


func attach_to_combatant(_combatant: Combatant) -> void:
	var on_hit := OnHit.new()
	on_hit.id = ON_HIT_ID
	on_hit.custom_func = _on_hit_inflict_bleed
	on_hits = [on_hit]


func detach_from_combatant(_combatant: Combatant) -> void:
	on_hits = []


func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	super.activate_weapon(targets, modifiers, custom_attack)
	# Runs AFTER super so on_hit's +1 bleed (if landed) is included in the double.
	# Fires regardless of hit — a fully-blocked swing still doubles existing bleed.
	for target in targets:
		_double_bleed(target)


func _on_hit_inflict_bleed(target: Node, _args: Array) -> void:
	if target == null or not is_instance_valid(target) or target.status_handler == null:
		return
	var bleed := BLEED_STATUS.duplicate() as BleedStatus
	bleed.duration = 1
	target.status_handler.add_status(bleed)


func _double_bleed(target: Node) -> void:
	if target == null or not is_instance_valid(target) or target.status_handler == null:
		return
	var existing := target.status_handler.get_status_by_id("bleed") as BleedStatus
	if existing == null or existing.duration <= 0:
		return
	# BleedStatus uses StackType.DURATION → add_status sums durations. Adding
	# `existing.duration` doubles the bleed timer.
	var add := BLEED_STATUS.duplicate() as BleedStatus
	add.duration = existing.duration
	target.status_handler.add_status(add)
