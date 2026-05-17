extends Relic

@export var heal_amount := 3
var relic_ui: RelicUI


func initialize_relic(relic_ui_node: RelicUI) -> void:
	relic_ui = relic_ui_node
	Events.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: Enemy) -> void:
	relic_ui.flash()
	var player := self.owner as Player
	if player and player.stats:
		player.stats.heal(heal_amount)


func deactivate_relic(_relic_ui: RelicUI) -> void:
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)
