class_name Card
extends Resource

#enum Type {ATTACK, SKILL, POWER}
enum Type {ATTACK, NAA, BLOCK}
enum TypeString {Attack, Action, Block}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

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
@export var defense: int
@export var exhausts: bool = false
@export var go_again: bool = false : get = get_go_again
@export var ai_value: int

@export_group("Card Visuals")
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream
@export var block_sound: AudioStream = preload("uid://df64e7qat73gs")

@export_group("Disabled Attributes")
@export var disable_attack: bool = false
@export var disable_defense: bool = false
@export var disable_pitch: bool = false

var owner: Variant
var on_hits: Array[OnHit]

func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY

func _get_targets(card_parent: Node) -> Array[Node]:
	var tree := card_parent.get_tree()
	match target:
		Target.SELF: return [owner]
		Target.ALL_ENEMIES: return tree.get_nodes_in_group("enemies")
		Target.EVERYONE: return tree.get_nodes_in_group("enemies") + tree.get_nodes_in_group("player")
		_: return []

func play(card_parent: Node, targets: Array[Node], stats: Stats, modifiers: ModifierHandler) -> void:
	if not is_single_targeted():
		targets = _get_targets(card_parent)
	
	if stats is CharacterStats:
		if type == Type.ATTACK and not targets.is_empty() and targets[0] is Enemy:
			Events.player_attack_declared.emit()
		stats.mana -= cost
	
	stats.action_points -= 1
	apply_effects(targets, modifiers)
	
	for targetx in targets:
		if type == Type.ATTACK:
			targetx.stats.block = 0
	
	if go_again:
		stats.action_points += 1

func discard_card() -> void:
	pass  # no longer emits — CardUI will emit signal

func pitch_card(stats: Stats) -> void:
	stats.mana += pitch

func sink_card(stats: Stats) -> void:
	pass

func block_card(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = defense
	block_effect.sound = block_sound
	block_effect.execute(targets)

func apply_effects(_targets: Array[Node], modifiers: ModifierHandler) -> void:
	pass

func apply_block_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = defense
	block_effect.sound = block_sound
	block_effect.execute(targets)

func get_default_tooltip() -> String:
	return tooltip_text

func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text

func do_stock_attack_damage_effect(targets: Array[Node], modifiers: ModifierHandler, custom_damage:int = attack) -> void:
	var damage_effect := AttackDamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(custom_damage, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.go_again = go_again
	
	damage_effect.on_hit_effects.append_array(on_hits)
	damage_effect.on_hit_effects.append_array(owner.active_on_hits)
	damage_effect.execute(targets)

func _on_card_discarded(card: Card) -> void:
	discarded_card = card


var discarded_card
func rampage(source: Node, qty: int) -> bool:
	Events.card_discarded.connect(_on_card_discarded)
	#var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	source.draw_card()
	discarded_card = null
	var discard_effect = DiscardRandomEffect.new()
	discard_effect.amount = qty
	discard_effect.execute([source])
	#var discarded_card: Card = await Events.card_discarded
	var timer = source.get_tree().create_timer(.01)
	print_debug("Rampage still has timer")
	await timer.timeout
	if discarded_card and (discarded_card.attack >= 6):
		return true
	else:
		return false

func sixloot(source: Node, qty: int) -> bool:
	#Events.card_discarded.connect(_on_card_discarded)
	#var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	source.draw_cards(qty)
	discarded_card = null
	var discard_effect = DiscardRandomSixEffect.new()
	discard_effect.amount = 1
	var all_six_discarded:bool = discard_effect.execute([source])
	#var discarded_card: Card = await Events.card_discarded
	#var timer = source.get_tree().create_timer(.01)
	#print_debug("Rampage still has timer")
	#await timer.timeout
	if all_six_discarded:
		return true
	else:
		return false

func get_go_again() -> bool:
	return go_again
