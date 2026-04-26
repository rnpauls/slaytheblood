class_name PoisonTipStatus
extends Status

var target_on_hits: Array[OnHit]

#Adds "stacks" to next attack power
#Set duration to 2 if created by an attack (it will reduce duration by 1 when attack is completed)

func get_tooltip() -> String:
	return tooltip % stacks

func initialize_status(target: Node) -> void:
	target_on_hits = target.active_on_hits
	var old_poison_tip_eff:=target_on_hits.filter(func(tmp_on_hit: OnHit): return tmp_on_hit.id=='poison_tip')
	if old_poison_tip_eff:
		print_debug("Initializing poison tip status but the on hit already exists")
		old_poison_tip_eff[0].effect.amount += stacks
		return
	var dmg_eff:= DamageEffect.new()
	dmg_eff.amount = stacks
	var on_hit:=OnHit.new()
	on_hit.effect = dmg_eff
	on_hit.ai_value = on_hit.effect.amount
	on_hit.id = "poison_tip"
	target_on_hits.append(on_hit)
	target.attack_completed.connect(apply_status.bind(target))

	if target is Player:
		Events.player_turn_ended.connect(apply_status.bind(target))
	else:
		Events.enemy_phase_ended.connect(apply_status.bind(target))
		
	#print_debug("Add bittering thorns modifier")


func apply_status(_target) -> void:
	status_applied.emit(self)

func _exit_tree() -> void:
	var old_poison_tip_eff:=target_on_hits.filter(func(tmp_on_hit: OnHit): return tmp_on_hit.id=='poison_tip')
	if old_poison_tip_eff:
		target_on_hits.erase(old_poison_tip_eff[0])
		return

func update() -> void:
	var old_poison_tip_eff:=target_on_hits.filter(func(tmp_on_hit: OnHit): return tmp_on_hit.id=='poison_tip')
	if old_poison_tip_eff:
		old_poison_tip_eff[0].effect.amount += stacks
		return
