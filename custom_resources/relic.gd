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

func get_tooltip() -> String:
	return tooltip

# --- Hook virtuals (called by RelicUI delegation) ---
# ui: the RelicUI node registered with Hook.

func modify_damage_additive(_dealer: Node, _target: Node, _vp: ValueProp, _ui: Node) -> int:
	return 0

func modify_damage_multiplicative(_dealer: Node, _target: Node, _vp: ValueProp, _ui: Node) -> float:
	return 1.0

func modify_block_additive(_blocker: Node, _vp: ValueProp, _ui: Node) -> int:
	return 0

func modify_block_multiplicative(_blocker: Node, _vp: ValueProp, _ui: Node) -> float:
	return 1.0

func before_card_played(_card: Card, _ctx: Dictionary, _ui: Node) -> void:
	pass

func after_card_played(_card: Card, _ctx: Dictionary, _ui: Node) -> void:
	pass

func after_turn_end(_side: String, _ui: Node) -> void:
	pass

func after_attack_completed(_attacker: Node, _ctx: Dictionary, _ui: Node) -> void:
	pass

func on_hit_dealt(_dealer: Node, _target: Node, _ctx: Dictionary, _ui: Node) -> void:
	pass

func on_hit_received(_dealer: Node, _target: Node, _ctx: Dictionary, _ui: Node) -> void:
	pass


func can_appear_as_reward(character: CharacterStats) -> bool:
	if starter_relic:
		return false

	if character_type == CharacterType.ALL:
		return true
		
	var relic_char_name: String = CharacterType.keys()[character_type].to_lower()
	var char_name := character.character_name.to_lower()
	
	return relic_char_name == char_name
