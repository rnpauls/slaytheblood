## One-shot buff: next non-attack action card played grants +1 AP. Stacks
## stored as INTENSITY so multiple charges accumulate (e.g. blocking with
## Mana-Threaded Greaves twice in a turn → next two NAAs each refund +1 AP).
## Auto-removes when stacks reach 0 (StatusUI._on_status_changed at
## scenes/status_handler/status_ui.gd:37).
class_name NextActionApBuffStatus
extends Status

var _target: Node = null


func initialize_status(target: Node) -> void:
	_target = target
	if not Events.player_card_played.is_connected(_on_player_card_played):
		Events.player_card_played.connect(_on_player_card_played)


func _on_player_card_played(card: Card) -> void:
	if stacks <= 0:
		return
	if card.type != Card.Type.NAA:
		return
	if _target is Combatant and _target.stats:
		_target.stats.action_points += 1
	stacks -= 1


func _exit_tree() -> void:
	if Events.player_card_played.is_connected(_on_player_card_played):
		Events.player_card_played.disconnect(_on_player_card_played)
