extends Card

## Cached top-card pitch from the most recent reveal. Subtracted from `attack`
## to determine actual damage. Reset at the end of each play.
var _runtime_top_pitch: int = 0
## Tracks whether pre_block_reveal already ran so apply_effects doesn't reveal twice.
var _reveal_done: bool = false

func get_default_tooltip() -> String:
	return tooltip_text % attack

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(attack, Modifier.Type.DMG_DEALT)

	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg

func get_attack_value() -> int:
	return attack - _runtime_top_pitch

func pre_block_reveal(source_owner: Node) -> void:
	_runtime_top_pitch = 0
	await _do_top_card_reveal(source_owner)
	_reveal_done = true

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var source_owner: Node = modifiers.get_parent()
	if not _reveal_done:
		await _do_top_card_reveal(source_owner)
	do_stock_attack_damage_effect(targets, modifiers, attack - _runtime_top_pitch)
	_reveal_done = false
	_runtime_top_pitch = 0

func _do_top_card_reveal(source_owner: Node) -> void:
	var top_card_arr: Array[Card] = source_owner.stats.draw_pile.reveal_top_cards(1)
	if top_card_arr.is_empty():
		print_debug("rabble on empty deck")
		return
	_runtime_top_pitch = top_card_arr[0].pitch
	print_debug("Revealed %s to rabble" % top_card_arr[0].id)
	Events.top_card_reveal_requested.emit(top_card_arr[0], source_owner)
	await Events.top_card_reveal_finished
