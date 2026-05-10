## Channel: Meteor — applied to runeblade now, fires at the bearer's next
## START_OF_TURN. Hits every enemy in the room with arcane damage and then
## expires. The id prefix "channel_" lets Quickened Cast detect it for
## immediate-fire bypass of the wait.
class_name ChannelMeteorStatus
extends Status

@export var damage: int = 12


func get_tooltip() -> String:
	return tooltip % damage


func initialize_status(_target: Node) -> void:
	pass


func apply_status(target: Node) -> void:
	if target and target.is_inside_tree():
		var enemies := target.get_tree().get_nodes_in_group("enemies")
		if not enemies.is_empty():
			var dmg := DamageEffect.new()
			dmg.amount = damage
			dmg.damage_kind = Card.DamageKind.ARCANE
			dmg.execute(enemies)
	status_applied.emit(self)
