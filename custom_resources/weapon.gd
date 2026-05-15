class_name Weapon
extends Resource

enum Type {SWORD, DAGGER, AXE, HAMMER, CLUB, CLAW, STAFF}
enum CharacterType {ALL, NINJA, BRUTE, RUNEBLADE}
enum Hands {ONEHAND, TWOHAND, OFFHAND}
enum Rarity {COMMON, UNCOMMON, RARE}

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

## Combatant currently wielding this weapon (always Player today, but typed
## as Combatant for symmetry with Card and to leave room for enemy-wielded
## weapons later). Null until WeaponHandler wires it up.
var owner: Combatant
var on_hits: Array[OnHit]

func initialize_weapon(_owner: WeaponUI) -> void:
	pass


## Called when this weapon is equipped/wielded by a combatant. Override to
## attach passive statuses or modifiers that should persist while wielded
## (e.g. Tower Shield's start-of-turn block, Twin Axes' damage modifier).
## Default no-op so existing weapons stay unchanged.
func attach_to_combatant(_combatant: Combatant) -> void:
	pass


## Inverse of attach_to_combatant. Called when the weapon is unequipped or
## its wielder dies. Override to remove anything attach added.
func detach_from_combatant(_combatant: Combatant) -> void:
	pass


## Returns true if this weapon would refund an action point if swung *now*.
## Default returns the static flag; dynamic weapons override to check live
## status / state on `owner`. Used by WeaponUI to show the go-again badge.
func would_go_again() -> bool:
	return go_again


## Returns the attack value to show on WeaponUI. Default returns the static
## `attack`; dynamic weapons (e.g. Berserker's Bite) override to compute from
## live owner state so the badge tracks the actual swing damage.
func get_display_attack() -> int:
	return attack


func activate_weapon(targets: Array[Node], modifiers: ModifierHandler, custom_attack:int = attack) -> void:
	Events.player_attack_declared.emit()
	do_stock_attack_damage_effect(targets, modifiers, custom_attack)
	for target in targets:
		target.stats.block = 0
	if owner:
		owner.stats.mana -= cost
		if not go_again: owner.stats.action_points -= 1
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

	if custom_attack > 0:
		packet.physical = modifiers.get_modified_value(custom_attack, Modifier.Type.DMG_DEALT)

	if zap > 0:
		packet.arcane = modifiers.get_modified_value(zap, Modifier.Type.ARCANE_DEALT)

	# Pure-zap weapons (physical == 0) aren't the rune-imbued swing runechants represent.
	if packet.physical > 0 and owner and owner.status_handler:
		var rune: Status = owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			packet.arcane += (rune as RunechantStatus).consume()

	# Unblockable mirrors Card.build_attack_packet — see notes there.
	if packet.physical > 0 and owner and owner.status_handler:
		var u := owner.status_handler.get_status_by_id("unblockable") as UnblockableStatus
		if u and not u.fresh and u.stacks > 0:
			packet.ignore_block = true

	return packet

## Rampage helper: draw `qty` extra cards into the source's hand, then randomly
## discard one card from that hand, preferring an attack ≥ 6 (the "six" filter).
## Returns true iff the discarded card actually was a 6+ atk — callers gate
## bonus effects on this. Symmetric across player and enemy: takes any
## Combatant and routes through its HandFacade so card scripts don't need to
## branch on `owner is Player`.
func sixloot(source: Node, qty: int) -> bool:
	var combatant := source as Combatant
	if combatant == null or combatant.hand_facade == null:
		return false
	if qty > 0:
		var tween := combatant.hand_facade.draw_cards(qty)
		if tween:
			await tween.finished
	var discard_effect := DiscardRandomSixEffect.new()
	discard_effect.amount = 1
	return discard_effect.execute([combatant])
