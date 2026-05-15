class_name Card
extends Resource

#enum Type {ATTACK, SKILL, POWER}
enum Type {ATTACK, NAA, BLOCK, TRASH}
enum TypeString {Attack, Action, Block, Trash}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}
enum DamageKind {PHYSICAL, ARCANE}


@export_group("Card Attributes")
@export var id: String
@export var type: Type
@export var rarity: Rarity
@export var target: Target
@export var cost: int
@export var pitch: int
@export var attack: int
## Arcane damage applied alongside the main attack (for split-damage cards).
## Resolves as a separate ZapEffect after the physical hit. Skills/NAAs can also
## set this to deal arcane without an attack component.
@export var zap: int = 0
@export var defense: int
@export var exhausts: bool = true
@export var go_again: bool = false : get = get_go_again
@export var action_points_granted: int = 0
@export var unplayable: bool = false
## Fleeting: if in hand at end of turn, the card is exhausted.
@export var fleeting: bool = false
## Reserve: does not count toward cards_per_turn when drawing at end of turn.
@export var reserve: bool = false
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

## The Combatant who currently owns this card (Player or Enemy). Set by the
## handler that draws/adds the card; null while the card is in a draw pile or
## reward stack. Effects, on-hits, and runechant triggers all guard against
## null since a card can briefly outlive its owner during scene teardown.
var owner: Combatant
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

## Hook for dynamic mana cost. Default returns the static `cost` field.
## Override in subclasses to reduce cost based on live owner state — e.g.
## runechant pile size, attacks_this_turn, discards_this_combat. Both
## play() and Stats.can_play_card route through this so the playability
## check and the actual mana spend stay in sync.
func get_play_cost() -> int:
	return cost

## Modifier-aware display helpers used by the hand UI so cards in hand show
## the value the player will actually deal/spend/block. Pass null for a raw
## read (e.g. inventory/deck-view screens that have no live modifiers).
func get_modified_attack(handler: ModifierHandler) -> int:
	var base := get_attack_value()
	if handler == null:
		return base
	return handler.get_modified_value(base, Modifier.Type.DMG_DEALT)

func get_modified_defense(handler: ModifierHandler) -> int:
	if handler == null:
		return defense
	return handler.get_modified_value(defense, Modifier.Type.BLOCK_GAINED)

func get_modified_cost(handler: ModifierHandler) -> int:
	var base := get_play_cost()
	if handler == null:
		return base
	return handler.get_modified_value(base, Modifier.Type.CARD_COST)

func _get_targets(_card_parent: Node) -> Array[Node]:
	# Resolve via owner: the CardUI may have been detached by card_ui.play()
	# before effects resolve, but owner (Player/Enemy) stays in the tree.
	if owner == null or not owner.is_inside_tree():
		return []
	var tree := owner.get_tree()

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
	# Per-play scratch: apply_effects in on-hit cards rebuilds this; build_attack_packet
	# consumes it. Without the clear, replays of the same card across a battle keep
	# appending, so a card like Quick Reflexes draws N cards on its Nth play.
	on_hits.clear()

	if not is_single_targeted():
		targets = _get_targets(card_parent)

	# Pay mana before player_attack_declared fires so dynamic-cost cards
	# (Cascade Strike) read the prior attack count, not their own. Otherwise
	# the card's own attack would self-discount and the UI cost would
	# disagree with the actual mana spend.
	char_stats.mana -= get_play_cost()
	char_stats.action_points -= 1

	if type == Type.ATTACK:
		if targets[0] is Enemy:
			Events.player_attack_declared.emit()
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

## Build a DamagePacket for this card's attack. Folds in the physical hit, the
## card's `zap` value (scaled by ARCANE_DEALT), and any runechants on the owner
## (consumed here, added raw). Used by do_stock_attack_damage_effect and exposed
## so the enemy intent system / damage previews can inspect a card's full hit
## profile without firing it.
##
## `custom_zap` defaults to the card's printed `zap` so attack callers behave
## as before; do_zap_effect overrides it to fire an arbitrary arcane amount
## (e.g. Runic Burst's 2× consumed runechants) without a physical component.
func build_attack_packet(modifiers: ModifierHandler, custom_damage: int = attack, custom_zap: int = zap) -> DamagePacket:
	var packet := DamagePacket.new()
	packet.source_card = self
	packet.source_owner = owner
	packet.sound = sound
	packet.go_again = go_again
	packet.on_hit_effects.append_array(on_hits)
	if owner:
		packet.on_hit_effects.append_array(owner.active_on_hits)

	if custom_damage > 0:
		packet.physical = modifiers.get_modified_value(custom_damage, Modifier.Type.DMG_DEALT)

	if custom_zap > 0:
		packet.arcane = modifiers.get_modified_value(custom_zap, Modifier.Type.ARCANE_DEALT)

	# Runechants on the attacker pop into the same packet — single decision
	# point for the defender instead of a sequence of small arcane events.
	# Pure-zap attacks (physical == 0) aren't the rune-imbued swing runechants represent.
	if packet.physical > 0 and owner and owner.status_handler:
		var rune: Status = owner.status_handler.get_status_by_id("runechant")
		if rune is RunechantStatus:
			packet.arcane += (rune as RunechantStatus).consume()

	return packet

## Fires `custom_zap` arcane damage at the given targets via a pure-arcane
## DamagePacket. Routing through the packet path is what gives enemies a chance
## to make a strategic block/mana decision via enemy_ai.defend_packet — the old
## direct-ZapEffect path forced auto-mana-spend on the enemy. With
## custom_damage=0, the runechant rider in build_attack_packet is bypassed
## (gated on packet.physical > 0), so detonators that pass an already-consumed
## rune count as custom_zap don't double-consume.
func do_zap_effect(targets: Array[Node], modifiers: ModifierHandler, custom_zap: int = zap) -> void:
	if custom_zap <= 0:
		return
	var packet := build_attack_packet(modifiers, 0, custom_zap)
	packet.execute(targets)

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
