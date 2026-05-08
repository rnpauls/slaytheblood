class_name Card
extends Resource

#enum Type {ATTACK, SKILL, POWER}
enum Type {ATTACK, NAA, BLOCK}
enum TypeString {Attack, Action, Block}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}
enum DamageKind {PHYSICAL, ARCANE}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
	
}

const PITCH_COLORS := {
	0: Color.GRAY,
	1: Color.RED,
	2: Color.YELLOW,
	3: Color.BLUE
}

@export_group("Card Attributes")
@export var id: String
@export var type: Type
@export var rarity: Rarity
@export var target: Target
@export var cost: int
@export var pitch: int
@export var attack: int
@export var damage_kind: DamageKind = DamageKind.PHYSICAL
## Arcane damage applied alongside the main attack (for split-damage cards).
## Resolves as a separate ZapEffect after the physical hit. Skills/NAAs can also
## set this to deal arcane without an attack component.
@export var zap: int = 0
@export var defense: int
@export var exhausts: bool = false
@export var go_again: bool = false : get = get_go_again
@export var action_points_granted: int = 0
@export var unplayable: bool = false
@export var ai_value: int
@export var ai_value_needs_attack: bool = false

@export_group("Card Visuals")
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream
@export var block_sound: AudioStream = preload("uid://df64e7qat73gs")

@export_group("Disabled Attributes")
@export var disable_attack: bool = false
@export var disable_defense: bool = false
@export var disable_pitch: bool = false
#@export var disable_cost: bool = false

var owner: Variant
var on_hits: Array[OnHit]

signal card_play_started(Card)
signal card_play_finished(Card)

## Per-card lifecycle signals — connect these on the owner (player/enemy) at draw time
## instead of using the global Events bus, so enemy card actions don't trigger player handlers.
signal pitched(card: Card)
signal sunk(card: Card)
signal blocked(card: Card)

#Used for Draw discard etc
var discarded_card: Card = null

func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY

func _get_targets(card_parent: Node) -> Array[Node]:
	var tree := card_parent.get_tree()
	
	match target:
		Target.SELF:
			return [owner]
		Target.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		Target.EVERYONE:
			return tree.get_nodes_in_group("enemies") + tree.get_nodes_in_group("player")
		_:
			return []

#Currently does not accept non-attack actions targetting enemies
func play(card_parent: Node, targets: Array[Node], char_stats: Stats, modifiers: ModifierHandler) -> void:
	card_play_started.emit(self)

	if not is_single_targeted():
		targets = _get_targets(card_parent)
	if type == Type.ATTACK:
		if targets[0] is Enemy:
			Events.player_attack_declared.emit()

	char_stats.mana -= cost
	char_stats.action_points -= 1
	await apply_effects(targets, modifiers)

	for targetx in targets:
		if type == Type.ATTACK:
			#if targetx is Enemy:
			targetx.stats.block = 0
	if go_again:
		char_stats.action_points += 1
	char_stats.action_points += action_points_granted
	card_play_finished.emit(self)

func discard_card() -> void:
	print("Discarded %s" % id)
	## card_discarded stays on the global bus — rampage() listens to it for cross-card tracking.
	Events.card_discarded.emit(self)

func pitch_card(char_stats: Stats) -> void:
	## Emit per-card signal so only the owning character's handler responds.
	pitched.emit(self)
	char_stats.mana += pitch

func sink_card(_char_stats: Stats) -> void:
	## Emit per-card signal so only the owning character's handler responds.
	sunk.emit(self)

func block_card(targets: Array[Node], modifiers: ModifierHandler) -> void:
	apply_block_effects(targets, modifiers)
	## Emit per-card signal so only the owning character's handler responds.
	blocked.emit(self)

func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass

## Optional hook run after an enemy declares this card but before the player
## declares blocks. Override to reveal cards, roll values, etc., so the intent
## (and any reveal animation) reflects the actual damage before the player commits.
## Default is a no-op. Awaited by EnemyActingState.
func pre_block_reveal(_source_owner: Node) -> void:
	pass

## Returns the base attack value used by the enemy intent display. Defaults to
## the static `attack` field; override when the value depends on runtime state
## set up in pre_block_reveal (e.g. ravenous_rabble subtracts top-card pitch).
func get_attack_value() -> int:
	return attack

func apply_block_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var block_effect := BlockEffect.new()
	var mod_def : = modifiers.get_modified_value(defense, Modifier.Type.BLOCK_GAINED)
	block_effect.amount = mod_def
	block_effect.sound = block_sound
	block_effect.execute(targets)

func get_default_tooltip() -> String:
	return tooltip_text

func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text

func do_stock_attack_damage_effect(targets: Array[Node], modifiers: ModifierHandler, custom_damage:int = attack) -> void:
	var packet := build_attack_packet(modifiers, custom_damage)
	packet.execute(targets)

## Build a DamagePacket for this card's attack. Folds in the main hit (routed
## by damage_kind), the card's `zap` value, and any runechants on the owner
## (consumed here). Used by do_stock_attack_damage_effect and exposed so the
## enemy intent system / damage previews can inspect a card's full hit profile
## without firing it.
func build_attack_packet(modifiers: ModifierHandler, custom_damage: int = attack) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source_card = self
	packet.source_owner = owner
	packet.sound = sound
	packet.go_again = go_again
	packet.on_hit_effects.append_array(on_hits)
	if owner:
		packet.on_hit_effects.append_array(owner.active_on_hits)

	var modified_main := modifiers.get_modified_value(custom_damage, Modifier.Type.DMG_DEALT)
	if damage_kind == DamageKind.PHYSICAL:
		packet.physical = modified_main
	else:
		packet.arcane = modified_main

	if zap > 0:
		packet.arcane += modifiers.get_modified_value(zap, Modifier.Type.DMG_DEALT)

	# Runechants on the attacker pop into the same packet — single decision
	# point for the defender instead of a sequence of small arcane events.
	if owner and owner.status_handler:
		var rune: Status = owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			packet.arcane += (rune as RunechantStatus).consume()

	return packet

## Fires the card's `zap` value as arcane damage at the given targets, with no
## physical component. For non-attack spells (NAAs that just zap) — attack
## cards already fold zap into their packet via do_stock_attack_damage_effect.
func do_zap_effect(targets: Array[Node], modifiers: ModifierHandler, custom_zap: int = zap) -> void:
	if custom_zap <= 0:
		return
	var zap_effect := ZapEffect.new()
	zap_effect.amount = modifiers.get_modified_value(custom_zap, Modifier.Type.DMG_DEALT)
	zap_effect.sound = sound
	zap_effect.execute(targets)

func _on_card_discarded(card: Card) -> void:
	discarded_card = card

#func rampage(source: Node, qty: int) -> bool:
	#Events.card_discarded.connect(_on_card_discarded)
	##var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	#source.draw_card()
	#discarded_card = null
	#var discard_effect = DiscardRandomEffect.new()
	#discard_effect.amount = qty
	#discard_effect.execute([source])
	##var discarded_card: Card = await Events.card_discarded
	#var timer = source.get_tree().create_timer(.01)
	#print_debug("Rampage still has timer")
	#await timer.timeout
	#if discarded_card and (discarded_card.attack >= 6):
		#return true
	#else:
		#return false

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
	discarded_card = null
	var discard_effect := DiscardRandomSixEffect.new()
	discard_effect.amount = 1
	return discard_effect.execute([combatant])

func get_go_again() -> bool:
	return go_again
