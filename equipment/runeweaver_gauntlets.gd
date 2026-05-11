class_name RuneweaverGauntletsEquipment
extends Equipment

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")
const MANA_COST := 2


func use_active_ability(owner_node: Node) -> void:
	var player := owner_node as Player
	if not player or not player.stats:
		return
	if player.stats.action_points < 1 or player.stats.mana < MANA_COST:
		return
	player.stats.action_points -= 1
	player.stats.mana -= MANA_COST
	var rune := RUNECHANT_STATUS.duplicate()
	rune.stacks = 1
	var status_effect := StatusEffect.new()
	status_effect.status = rune
	status_effect.execute([player])
	player.stats.action_points += 1
	super.use_active_ability(owner_node)
