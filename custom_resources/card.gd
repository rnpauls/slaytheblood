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
@export var go_again: bool = false

@export_group("Card Visuals")
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream

@export_group("Disabled Attributes")
@export var disable_attack: bool = false
@export var disable_defense: bool = false
@export var disable_pitch: bool = false
#@export var disable_cost: bool = false

var discarded_card: Card = null

func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY

func _get_targets(card_parent: Node) -> Array[Node]:
	var tree := card_parent.get_tree()
	
	match target:
		Target.SELF:
			return tree.get_nodes_in_group("player")
		Target.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		Target.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemies")
		_:
			return []

#Currently does not accept non-attack actions targetting enemies
func play(card_parent: Node, targets: Array[Node], char_stats: CharacterStats, modifiers: ModifierHandler) -> void:
	Events.card_played.emit(self)
	char_stats.mana -= cost
	char_stats.action_points -= 1
	
	#for targetx in targets:
		#if targetx is Enemy:
			#targetx.defend_attack(attack, modifiers, go_again)
			#Could emit a signal with this info, and include the targets, then connect to each enemy and await an answer
	if not is_single_targeted():
		targets = _get_targets(card_parent)
	await apply_effects(targets, modifiers)
	for targetx in targets:
		#if targetx is Enemy:
		targetx.stats.block = 0
	if go_again:
		char_stats.action_points += 1

func discard_card() -> void:
	print("Discarded %s" % id)
	Events.card_discarded.emit(self)

func pitch_card(char_stats: CharacterStats) -> void:
	Events.card_pitched.emit(self)
	char_stats.mana += pitch

func sink_card(char_stats: CharacterStats) -> void:
	Events.card_sunk.emit(self)

func block_card(targets: Array[Node], modifiers: ModifierHandler) -> void:
	apply_block_effects(targets, modifiers)
	Events.card_blocked.emit(self)

func apply_effects(_targets: Array[Node], modifiers: ModifierHandler) -> void:
	pass

func apply_block_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = defense
	block_effect.sound = sound
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
	damage_effect.execute(targets)

func _on_card_discarded(card: Card) -> void:
	discarded_card = card

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
