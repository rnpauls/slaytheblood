extends Relic

@export var gold_gain := 20


func activate_relic(relic_ui: RelicUI) -> void:
	Events.relic_gold_granted.emit(gold_gain)
	relic_ui.flash()
