class_name Weapon
extends Resource

enum Type {SWORD, DAGGER, AXE, HAMMER, CLUB, CLAW, STAFF}
enum CharacterType {ALL, NINJA, BRUTE, RUNEBLADE}
enum Hands {ONEHAND, TWOHAND, OFFHAND}
enum Rarity {COMMON, UNCOMMON, RARE}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
	
}

@export var weapon_name: String
@export var id: String
@export var type: Type
@export var rarity: Rarity
@export var character_type: CharacterType
@export var hands: Hands
@export var starter_weapon: bool = false
## If false, this item is filtered out of post-battle drafts when already owned.
@export var allow_duplicate_in_draft: bool = false
@export var icon: Texture
@export var sound: AudioStream
@export_multiline var tooltip: String

@export var attack: int
@export var damage_kind: Card.DamageKind = Card.DamageKind.PHYSICAL
## Arcane damage applied alongside the main weapon hit (split-damage weapons).
## Resolves through the same DamagePacket as `attack`, so runechants and the
## defender's mana spend see one bundled hit, not two events.
@export var zap: int = 0
@export var cost: int
@export var go_again: bool = false
@export var is_single_use: bool = false
@export var attacks_per_turn: int = 1
@export var attacks_this_turn: int = 0

signal weapon_used_up

var owner: Variant
var on_hits: Array[OnHit]

func initialize_weapon(_owner: WeaponUI) -> void:
	pass


func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack:int = attack) -> void:
	Events.player_attack_declared.emit()
	do_stock_attack_damage_effect(targets, modifiers, custom_attack)
	for target in targets:
		target.stats.block = 0
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
	var packet := build_attack_packet(modifiers, custom_attack)
	packet.execute(targets)

## Build a DamagePacket for this weapon's swing. Mirrors Card.build_attack_packet
## so weapons participate in the same arcane / runechant pipeline as cards —
## a Runeblade weapon attack will pop runechants and split into one packet.
func build_attack_packet(modifiers: ModifierHandler, custom_attack: int = attack) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source_owner = owner
	packet.sound = sound
	packet.go_again = go_again
	packet.on_hit_effects.append_array(on_hits)
	if owner:
		packet.on_hit_effects.append_array(owner.active_on_hits)

	var modified_main := modifiers.get_modified_value(custom_attack, Modifier.Type.DMG_DEALT)
	if damage_kind == Card.DamageKind.PHYSICAL:
		packet.physical = modified_main
	else:
		packet.arcane = modified_main

	if zap > 0:
		packet.arcane += modifiers.get_modified_value(zap, Modifier.Type.DMG_DEALT)

	if owner and owner.status_handler:
		var rune := owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			packet.arcane += (rune as RunechantStatus).consume()

	return packet
