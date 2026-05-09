class_name Relic
extends Resource

enum Type {START_OF_TURN, START_OF_COMBAT, END_OF_TURN, END_OF_COMBAT, EVENT_BASED}
enum CharacterType {ALL, NINJA, BRUTE, RUNEBLADE}

@export var relic_name: String
@export var id: String
@export var type: Type
@export var character_type: CharacterType
@export var starter_relic: bool = false
@export var icon: Texture
@export_multiline var tooltip: String

## Combatant that holds this relic. Set by RelicHandler.add_relic. Lets relic
## scripts read self.owner.stats / self.owner.status_handler /
## self.owner.player_handler instead of looking up the player by group name.
## Always Player today; typed Combatant for symmetry with Card / Weapon /
## Equipment owners.
var owner: Combatant


func initialize_relic(_relic_ui: RelicUI) -> void:
	pass


func activate_relic(_relic_ui: RelicUI) -> void:
	pass


# This method should be implemented by event-based relics
# which connect to the EventBus to make sure that they are
# disconnected when a relic gets removed.
func deactivate_relic(_relic_ui: RelicUI) -> void:
	pass


func get_tooltip() -> String:
	return tooltip


func can_appear_as_reward(character: CharacterStats) -> bool:
	if starter_relic:
		return false

	if character_type == CharacterType.ALL:
		return true
		
	var relic_char_name: String = CharacterType.keys()[character_type].to_lower()
	var char_name := character.character_name.to_lower()
	
	return relic_char_name == char_name
