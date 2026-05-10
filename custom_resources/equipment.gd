class_name Equipment
extends Resource

enum Slot {HEAD, CHEST, ARMS, LEGS, OFFHAND}
enum Rarity {COMMON, UNCOMMON, RARE}
enum CharacterType {ALL, NINJA, BRUTE, RUNEBLADE}

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
## If true: equipment dumps its full current_block in one defend and breaks.
## If false: defends for current_block worth of damage, then decrements by 1; breaks at 0.
@export var single_use: bool = false
@export var starter_equipment: bool = false
## If false, this item is filtered out of post-battle drafts when already owned.
@export var allow_duplicate_in_draft: bool = false

@export_group("Visuals")
@export var icon: Texture
@export var sound: AudioStream
@export_multiline var tooltip: String

@export_group("Block")
@export var max_block: int = 1
## Persistent across battles and saves. -1 means "uninitialized" — set to max_block on first equip.
@export var current_block: int = -1

@export_group("Persistence Exceptions")
## When true: current_block resets to max_block at end of battle. Granted by special items / events.
@export var regenerates_each_battle: bool = false
## When true: equipment is not destroyed at 0; remains in slot but unusable until regenerated.
@export var unbreakable: bool = false

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
var used_this_attack: bool = false
var ability_used_this_turn: bool = false
## Combatant who owns this equipment (always Player today). Null until
## EquipmentHandler wires it up.
var owner: Combatant


func initialize_equipment(_owner) -> void:
	if current_block < 0:
		current_block = max_block
	used_this_attack = false
	ability_used_this_turn = false


## Called when an equipment is used to defend against an incoming attack.
## Returns the block amount applied. After the call, equipment may be destroyed
## (caller should check is_destroyed()).
func consume_block_for_attack() -> int:
	var amount := current_block
	used_this_attack = true
	if single_use:
		current_block = 0
	else:
		current_block = max(0, current_block - 1)
	return amount


func is_destroyed() -> bool:
	return current_block <= 0 and not unbreakable


## Reset for a new incoming attack: re-enable click but do NOT restore block value.
## Block restoration happens at end-of-battle (only when regenerates_each_battle).
func reset_for_attack() -> void:
	used_this_attack = false


## Hook fired by EquipmentHandler.attempt_to_block right after the block has been
## applied. Subclasses override to add reactive effects (draw a card, gain muscle,
## reflect damage, etc.). Fires whether or not the equipment was destroyed by the
## block — so a one-shot equipment can still bank an effect on its dying use.
func on_block_consumed(_owner_node: Node) -> void:
	pass


## Hook fired by EquipmentHandler._destroy_equipment right before the equipment
## is removed/disabled. Subclasses override to grant a "death rattle" effect.
func on_destroyed(_owner_node: Node) -> void:
	pass


## Cleanup hook fired by EquipmentHandler when the equipment is being removed
## from a slot (destroyed or swapped out). Subclasses that connect to global
## signals in initialize_equipment MUST disconnect them here, or stale instances
## will keep responding after they're gone.
func deactivate_equipment(_owner_node: Node) -> void:
	pass


## Restore equipment to full at end of battle (only items with regenerates_each_battle).
func restore_for_battle() -> void:
	if regenerates_each_battle:
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
