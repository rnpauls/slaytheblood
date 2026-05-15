## Aegis Thorns: Bulwark Knight passive. While the bearer has 5+ block, every
## physical attack against them reflects THORNS damage back to the attacker.
## Mirrors ThornsStatus's reflect path (DamageEffect with NO_MODIFIER, fires
## even on fully-blocked swings) but gates on the bearer's live block value
## instead of stacking like a regular status.
##
## Standalone status (rather than dynamically adding/removing the regular
## thorns) so we don't fight stack accounting with whatever else might apply
## thorns this fight.
class_name AegisThornsStatus
extends Status

const THORNS_AMOUNT := 2
const BLOCK_THRESHOLD := 5

var _bearer: Combatant = null
var _bound_attacked: Callable


func get_tooltip() -> String:
	return tooltip


func initialize_status(target: Node) -> void:
	if target == null:
		return
	_bearer = target as Combatant
	_bound_attacked = _on_combatant_attacked
	if not Events.combatant_attacked.is_connected(_bound_attacked):
		Events.combatant_attacked.connect(_bound_attacked)


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func _on_combatant_attacked(victim: Node, attacker: Node, attempted: int, _damage_dealt: int) -> void:
	if victim != _bearer or attacker == null or attacker == _bearer:
		return
	if attempted <= 0 or not is_instance_valid(attacker):
		return
	if not is_instance_valid(_bearer) or _bearer.stats == null:
		return
	# stats.block can drop mid-attack as block absorbs the swing — combatant_attacked
	# fires AFTER the absorb, so we read the post-block value. Bulwark Knight's
	# +5/turn from Tower Shield typically keeps this >0 even after one solid hit.
	if _bearer.stats.block < BLOCK_THRESHOLD:
		return
	var dmg := DamageEffect.new()
	dmg.amount = THORNS_AMOUNT
	dmg.damage_kind = Card.DamageKind.PHYSICAL
	dmg.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	dmg.execute([attacker])


func _exit_tree() -> void:
	if _bound_attacked and Events.combatant_attacked.is_connected(_bound_attacked):
		Events.combatant_attacked.disconnect(_bound_attacked)
