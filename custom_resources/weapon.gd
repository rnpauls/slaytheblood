class_name Weapon
extends Resource

enum Type {SWORD, DAGGER, AXE, HAMMER, CLUB, CLAW, STAFF}
enum CharacterType {ALL, ASSASSIN, WARRIOR, WIZARD}
enum Hands {ONEHAND, TWOHAND, OFFHAND}

@export var weapon_name: String
@export var id: String
@export var type: Type
@export var character_type: CharacterType
@export var hands: Hands
@export var starter_weapon: bool = false
@export var icon: Texture
@export var sound: AudioStream
@export_multiline var tooltip: String

@export var attack: int
@export var cost: int 
@export var go_again: bool = false
@export var attacks_per_turn: int = 1
@export var attacks_this_turn: int = 0

signal weapon_used_up

func initialize_weapon(_owner: WeaponUI) -> void:
	pass


func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack:int = attack) -> void:
	do_stock_attack_damage_effect(targets, modifiers, custom_attack)
	var player = targets[0].get_tree().get_first_node_in_group("player") as Player
	player.stats.mana -= cost
	if not go_again: player.stats.action_points -= 1
	attacks_this_turn += 1
	if attacks_this_turn >= attacks_per_turn: weapon_used_up.emit()

func reset() -> void:
	attacks_this_turn = 0

# This method should be implemented by event-based relics
# which connect to the EventBus to make sure that they are
# disconnected when a relic gets removed.
#func deactivate_weapon(_owner: RelicUI) -> void:
	#pass


func get_tooltip() -> String:
	return tooltip


func can_appear_as_reward(character: CharacterStats) -> bool:
	if starter_weapon:
		return false

	if character_type == CharacterType.ALL:
		return true
		
	var weapon_char_name: String = CharacterType.keys()[character_type].to_lower()
	var char_name := character.character_name.to_lower()
	
	return weapon_char_name == char_name

func do_stock_attack_damage_effect(targets: Array[Node], modifiers: ModifierHandler, custom_attack: int = attack) -> void:
	var damage_effect := AttackDamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(custom_attack, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.go_again = go_again
	damage_effect.execute(targets)
