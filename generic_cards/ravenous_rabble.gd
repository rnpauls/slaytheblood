extends Card

## Cached top-card pitch from the most recent reveal. Subtracted from `attack`
## to determine actual damage. Reset at the end of each play.
var _runtime_top_pitch: int = 0
## Tracks whether pre_block_reveal already ran so apply_effects doesn't reveal twice.
var _reveal_done: bool = false

func get_attack_value() -> int:
	return attack - _runtime_top_pitch

func pre_block_reveal(_source_owner: Node) -> void:
	_runtime_top_pitch = 0
	await _do_top_card_reveal()
	_reveal_done = true

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not _reveal_done:
		await _do_top_card_reveal()
	do_stock_attack_damage_effect(targets, modifiers, attack - _runtime_top_pitch)
	_reveal_done = false
	_runtime_top_pitch = 0

func _do_top_card_reveal() -> void:
	if owner == null:
		return
	var top_card_arr: Array[Card] = owner.stats.draw_pile.reveal_top_cards(1)
	if top_card_arr.is_empty():
		print_debug("rabble on empty deck")
		return
	_runtime_top_pitch = top_card_arr[0].pitch
	print_debug("Revealed %s to rabble" % top_card_arr[0].id)
	Events.top_card_reveal_requested.emit(top_card_arr[0], owner)
	await Events.top_card_reveal_finished
