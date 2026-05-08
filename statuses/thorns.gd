## Thorns: when the bearer is physically attacked, deal `stacks` damage back
## to the attacker — even if the attack was fully blocked. INTENSITY-stacked,
## decays at end of bearer's turn. Used by Reflect Stance (enemy NAA) and
## Spiked Pauldrons (player equipment).
##
## Listens to combatant_attacked (fires unconditionally per attack) rather than
## combatant_damaged (gated on residual damage) so a fully-blocked Spiked
## Pauldrons block still punishes the attacker.
##
## The reflect uses a plain DamageEffect (not AttackDamageEffect) so it doesn't
## re-fire combatant_attacked — prevents Thorns-vs-Thorns infinite loops.
class_name ThornsStatus
extends Status

var _target: Node = null


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	_target = target
	Events.combatant_attacked.connect(_on_combatant_attacked)
	if target is Player:
		Events.player_turn_ended.connect(apply_status.bind(target))
	else:
		Events.enemy_phase_ended.connect(apply_status.bind(target))


func _on_combatant_attacked(victim: Node, attacker: Node, attempted: int, _damage_dealt: int) -> void:
	if victim != _target or attacker == null or attacker == _target:
		return
	if stacks <= 0 or attempted <= 0 or not is_instance_valid(attacker):
		return
	var dmg := DamageEffect.new()
	dmg.amount = stacks
	dmg.damage_kind = Card.DamageKind.PHYSICAL
	dmg.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	dmg.execute([attacker])


func apply_status(_target_arg) -> void:
	status_applied.emit(self)


func _exit_tree() -> void:
	if Events.combatant_attacked.is_connected(_on_combatant_attacked):
		Events.combatant_attacked.disconnect(_on_combatant_attacked)
