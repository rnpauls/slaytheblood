extends Relic

@export var mana_gain := 1
var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.card_sunk.connect(_on_card_sunk)


func _on_card_sunk(_card: Card) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.stats:
		player.stats.mana += mana_gain


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.card_sunk.is_connected(_on_card_sunk):
		Events.card_sunk.disconnect(_on_card_sunk)
