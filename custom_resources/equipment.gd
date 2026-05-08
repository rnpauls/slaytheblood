class_name Equipment
extends Resource

enum Slot {HEAD, CHEST, ARMS, LEGS, OFFHAND}
enum Rarity {COMMON, UNCOMMON, RARE}
enum CharacterType {ALL, NINJA, BRUTE, RUNEBLADE}
## ONE_SHOT: equipment is permanently removed from the inventory if destroyed mid-battle.
## REUSABLE: equipment restores to max_block at end of battle (current_block reset).
enum Persistence {ONE_SHOT, REUSABLE}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
}

@export_group("Equipment Attributes")
@export var equipment_name: String
@export var id: String
@export var slot: Slot
@export var rarity: Rarity
@export var character_type: CharacterType
@export var persistence: Persistence
## If true: equipment is destroyed when used to block (regardless of remaining block).
## If false: current_block decrements by 1 per use; equipment is destroyed when current_block reaches 0.
@export var break_on_use: bool = false
@export var starter_equipment: bool = false
## If false, this item is filtered out of post-battle drafts when already owned.
@export var allow_duplicate_in_draft: bool = false

@export_group("Visuals")
@export var icon: Texture
@export var sound: AudioStream
@export_multiline var tooltip: String

@export_group("Block")
@export var max_block: int = 1

@export_group("Triggered Ability")
## Optional: a Relic resource activated when this equipment is used to block.
## Reuses the existing Relic.activate_relic system. The trigger fires before the
## block value is added to player.stats.block.
@export var trigger_relic: Relic

@export_group("Active Ability")
## When true, the equipment can be clicked during the player's action phase to
## trigger a per-turn active ability. Subclasses override use_active_ability().
@export var has_active_ability: bool = false

# Runtime state — not exported.
var current_block: int
var used_this_attack: bool = false
var ability_used_this_turn: bool = false
var owner: Variant


func initialize_equipment(_owner) -> void:
	current_block = max_block
	used_this_attack = false
	# Reset here so the flag never leaks across battles via the saved Resource
	# (Godot serializes script `var`s, not just `@export`s).
	ability_used_this_turn = false


## Called when an equipment is used to defend against an incoming attack.
## Returns true if the equipment was destroyed by this use.
## The caller is responsible for adding the returned block value to player.stats.block
## (kept as a separate step so the EquipmentHandler can route through BlockEffect for sound/UI).
func consume_block_for_attack() -> int:
	var amount := current_block
	used_this_attack = true
	if break_on_use:
		current_block = 0
	else:
		current_block = max(0, current_block - 1)
	return amount


func is_destroyed() -> bool:
	return current_block <= 0


## Reset for a new incoming attack: re-enable click but do NOT restore block value.
## Block restoration happens at end-of-battle (only for REUSABLE).
func reset_for_attack() -> void:
	used_this_attack = false


## Restore equipment to full at end of battle (REUSABLE only).
func restore_for_battle() -> void:
	if persistence == Persistence.REUSABLE:
		current_block = max_block
		used_this_attack = false
		ability_used_this_turn = false


## Returns true if the equipment's active ability can be triggered right now
## (has the ability, not yet used this turn, and the owner has at least 1 AP).
func can_use_active_ability(owner_node: Node) -> bool:
	if not has_active_ability or ability_used_this_turn:
		return false
	var p := owner_node as Player
	return p != null and p.stats != null and p.stats.action_points >= 1


## Trigger the active ability. Subclasses override this with their effect, then
## call super.use_active_ability(owner_node) to mark the per-turn cooldown.
## Callers should gate on can_use_active_ability() first.
func use_active_ability(_owner_node: Node) -> void:
	ability_used_this_turn = true


func reset_active_ability() -> void:
	ability_used_this_turn = false


func get_tooltip() -> String:
	return tooltip


func can_appear_as_reward(character: CharacterStats) -> bool:
	if starter_equipment:
		return false

	if character_type == CharacterType.ALL:
		return true

	var equip_char_name: String = CharacterType.keys()[character_type].to_lower()
	var char_name := character.character_name.to_lower()

	return equip_char_name == char_name
