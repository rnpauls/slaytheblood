class_name CatalogerStatus
extends Status

# Granted by Catalog Tome. Each START_OF_TURN, the wielder reads the opposing
# player's draw pile size and (a) gains block equal to that size, (b) takes
# a flat DMG_DEALT modifier equal to floor(size / DAMAGE_DIVISOR)

const DAMAGE_DIVISOR := 3
const SOURCE_ID := "cataloger"


func get_tooltip() -> String:
	return tooltip


func apply_status(target: Node) -> void:
	if not target or not target.is_inside_tree():
		status_applied.emit(self)
		return

	var deck_size := _opponent_deck_size(target)

	if target.get("stats"):
		target.stats.block += deck_size

	if target.get("modifier_handler"):
		var dmg_dealt: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
		if dmg_dealt:
			dmg_dealt.remove_value(SOURCE_ID)
			var bonus := ModifierValue.create_new_modifier(SOURCE_ID, ModifierValue.Type.FLAT)
			bonus.flat_value = deck_size / DAMAGE_DIVISOR
			dmg_dealt.add_new_value(bonus)

	status_applied.emit(self)


func _opponent_deck_size(target: Node) -> int:
	var tree := target.get_tree()
	var opponents: Array
	if target is Enemy:
		opponents = tree.get_nodes_in_group("player")
	else:
		opponents = tree.get_nodes_in_group("enemies")
	for opp in opponents:
		var stats = opp.get("stats")
		if stats and stats.get("deck"):
			return stats.draw_pile.cards.size()
	return 0
