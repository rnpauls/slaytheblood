## InertCard: locks N cards in the player's hand for the duration. While inert
## a card cannot be played, pitched, or used to block — every check site
## already gates on `card.unplayable / disable_pitch / disable_defense`, so we
## flip those flags directly and remember the originals to restore on expire.
##
## INTENSITY stacking + END_OF_TURN tick: applied during the enemy phase, lives
## through the player's next turn, and the type-based tick (player_handler's
## apply_statuses_by_type END_OF_TURN) drops duration to 0 at the end of that
## turn. _exit_tree runs in the same frame and restores the flags before the
## next player turn begins.
##
## New stacks pick new cards (up to hand size), additional applications
## refresh the duration. Cards added to hand mid-turn after Inert applied are
## NOT auto-inerted — only cards in hand at apply time are picked.
class_name InertCardStatus
extends Status

const INERT_MODULATE := Color(0.4, 0.4, 0.4, 0.7)

var _target_ref: Node = null
## Card -> original {unplayable, disable_pitch, disable_defense}. We restore
## exactly the saved flags on expire so cards that were already e.g.
## disable_pitch don't become wrongly pitchable when Inert wears off.
var _saved_flags: Dictionary = {}
var _inert_cards: Array[Card] = []
var _inert_uis: Array[CardUI] = []


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	_target_ref = target
	_pick_and_inert(target, stacks)


## Called when re-added (INTENSITY stack_type sums stacks via add_status).
## Pick additional cards if our locked count is below the new stacks.
func update() -> void:
	if _target_ref == null:
		return
	var need: int = stacks - _inert_cards.size()
	if need > 0:
		_pick_and_inert(_target_ref, need)


func apply_status(_target: Node) -> void:
	# END_OF_TURN tick: handler decrements duration after this returns; when
	# duration <= 0 the StatusUI queue_frees and _exit_tree restores flags.
	status_applied.emit(self)


func _pick_and_inert(target: Node, count: int) -> void:
	var combatant := target as Combatant
	if combatant == null or combatant.hand_facade == null:
		return
	var all_cards: Array[Card] = combatant.hand_facade.get_hand()
	var available: Array = all_cards.filter(
		func(c: Card) -> bool: return c != null and not (c in _inert_cards)
	)
	for _i in count:
		if available.is_empty():
			return
		var idx: int = randi() % available.size()
		var card: Card = available[idx]
		available.remove_at(idx)
		_make_inert(card, target)


func _make_inert(card: Card, target: Node) -> void:
	_saved_flags[card] = {
		"unplayable": card.unplayable,
		"disable_pitch": card.disable_pitch,
		"disable_defense": card.disable_defense,
	}
	card.unplayable = true
	card.disable_pitch = true
	card.disable_defense = true
	_inert_cards.append(card)
	_tint_card_ui(card, target, INERT_MODULATE)


func _tint_card_ui(card: Card, target: Node, color: Color) -> void:
	if target is Enemy:
		var card_ui: CardUI = (target as Enemy).card_ui_map.get(card, null)
		if is_instance_valid(card_ui):
			card_ui.modulate = color
			if color != Color.WHITE:
				_inert_uis.append(card_ui)
		return
	if target is Player:
		var facade := (target as Player).hand_facade as PlayerHandFacade
		if facade == null:
			return
		for card_ui in facade.get_card_uis():
			if card_ui is PlayerCardUI and (card_ui as PlayerCardUI).card == card:
				card_ui.modulate = color
				if color != Color.WHITE:
					_inert_uis.append(card_ui)
				break


func _exit_tree() -> void:
	for card in _inert_cards:
		if card == null:
			continue
		var saved: Dictionary = _saved_flags.get(card, {})
		card.unplayable = saved.get("unplayable", false)
		card.disable_pitch = saved.get("disable_pitch", false)
		card.disable_defense = saved.get("disable_defense", false)
	for card_ui in _inert_uis:
		if is_instance_valid(card_ui):
			card_ui.modulate = Color.WHITE
	_inert_cards.clear()
	_saved_flags.clear()
	_inert_uis.clear()
