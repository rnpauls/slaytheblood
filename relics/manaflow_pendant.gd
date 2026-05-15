## EVENT_BASED. After your first attack each turn, gain 1 Floodgate, so the
## arcane card you play next benefits from the buff. Mirrors bloodied_pelt's
## event-connect / event-disconnect skeleton.
extends Relic

const FLOODGATE_STATUS = preload("res://statuses/floodgate.tres")

var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.player_first_attack_played.connect(_on_first_attack)


func _on_first_attack(_card: Card) -> void:
	if relic_ui:
		relic_ui.flash()
	var player := self.owner as Player
	if player and player.status_handler:
		var fg := FLOODGATE_STATUS.duplicate()
		fg.stacks = 1
		player.status_handler.add_status(fg)


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.player_first_attack_played.is_connected(_on_first_attack):
		Events.player_first_attack_played.disconnect(_on_first_attack)
