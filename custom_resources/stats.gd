class_name Stats
extends Resource

signal stats_changed

@export var character_name: String
@export var art: Texture
@export var display_height: float = 152.0

@export_group("Gameplay Data")
@export var max_health := 1 : set = set_max_health
@export var starting_deck: CardPile
@export var starting_inventory: Inventory
@export var cards_per_turn: int

@export_group("Equipped Hands")
## hand_left and hand_right each hold either a Weapon or an Equipment (offhand).
## Typed as Resource because GDScript doesn't support union types.
@export var hand_left: Resource
@export var hand_right: Resource

@export_group("Equipped Equipment")
@export var equipment_head: Equipment
@export var equipment_chest: Equipment
@export var equipment_arms: Equipment
@export var equipment_legs: Equipment

var mana: int : set = set_mana
var action_points: int : set = set_action_points
var inventory: Inventory
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile
var exhaust: CardPile
var health: int : set = set_health
var block: int : set = set_block

## Dynamic-cost counters. Wired by Player listeners (player.gd) so cards
## with overridden get_play_cost() can read the live state (e.g. Cascade
## Strike's cost drops by attacks already declared this turn). Setters
## emit stats_changed so CardVisuals.refresh_cost() picks up the change.
var attacks_this_turn: int = 0 : set = set_attacks_this_turn
var discards_this_combat: int = 0 : set = set_discards_this_combat

func set_health(value : int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()

func set_max_health(value : int) -> void:
	var diff := value - max_health
	max_health = value

	if diff > 0:
		health += diff
	elif health > max_health:
		health = max_health

	stats_changed.emit()

func set_block(value : int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()

func set_mana(value: int) -> void:
	mana = value
	stats_changed.emit()

func set_action_points(value: int) -> void:
	action_points = value
	stats_changed.emit()

func reset_mana() -> void:
	mana = 0

func reset_action_points() -> void:
	action_points = 1

func set_attacks_this_turn(value: int) -> void:
	attacks_this_turn = value
	stats_changed.emit()

func set_discards_this_combat(value: int) -> void:
	discards_this_combat = value
	stats_changed.emit()

func can_play_card(card:Card) -> bool:
	if card.type == Card.Type.BLOCK:
		return false
	return mana >= card.get_play_cost() and action_points >= 1 and not card.unplayable

func create_instance() -> Resource:
	var instance: Stats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	instance.reset_action_points()
	instance.inventory = instance.starting_inventory.duplicate()
	instance.deck = instance.starting_deck.duplicate()
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	instance.exhaust = CardPile.new()
	# Fresh combat: reset the dynamic-cost counters so they start from 0.
	instance.attacks_this_turn = 0
	instance.discards_this_combat = 0
	return instance

## prevention: how much arcane to mana-spend on. -1 = auto-spend everything
## available (the default — right for the player today, since the player has
## no UI to choose). The enemy AI passes an explicit value so it can keep mana
## in reserve for offense or pitch additional cards to spend more.
func take_damage(damage : int, damage_kind: Card.DamageKind = Card.DamageKind.PHYSICAL, prevention: int = -1) -> int:
	if damage <= 0:
		return 0
	if damage_kind == Card.DamageKind.ARCANE:
		var to_prevent: int
		if prevention < 0:
			to_prevent = mini(damage, mana)
		else:
			to_prevent = clampi(prevention, 0, mini(damage, mana))
		mana -= to_prevent
		var unprevented := damage - to_prevent
		health -= unprevented
		return unprevented
	var initial_damage = damage
	damage = clampi(damage - block, 0, damage)
	block = clampi(block - initial_damage, 0, block)
	health -= damage
	return damage

func heal(amount : int) -> void:
	health += amount

func mill(amount: int) -> Array[Card]:
	var milled_cards: Array[Card]
	for card_num in amount:
		var milled_card = draw_pile.draw_card()
		if milled_card:
			discard.add_card(milled_card)
			milled_cards.append(milled_card)
	return milled_cards


## True if a slot can hold either a Weapon or an offhand Equipment.
func _is_hand_free(slot: Resource) -> bool:
	return slot == null


static func is_two_handed_weapon(item: Resource) -> bool:
	return item is Weapon and item.hands == Weapon.Hands.TWOHAND


## A 2H weapon is stored only in hand_left; hand_right stays null while it's equipped.
func is_two_handed_equipped() -> bool:
	return is_two_handed_weapon(hand_left)


func add_weapon(new_weapon: Weapon) -> void:
	var cloned: = new_weapon.duplicate()
	inventory.add_weapon(cloned)
	if is_two_handed_weapon(cloned):
		if hand_left == null and hand_right == null:
			hand_left = cloned
	else:
		if is_two_handed_equipped():
			return
		if _is_hand_free(hand_left):
			hand_left = cloned
		elif _is_hand_free(hand_right):
			hand_right = cloned


## Adds equipment to the inventory. If the matching slot is empty, equips it automatically
## (offhand equipment goes into hand_left/hand_right just like an offhand weapon).
func add_equipment(new_equipment: Equipment) -> void:
	var cloned: Equipment = new_equipment.duplicate()
	# Resolve the -1 sentinel immediately so inventory views show "max/max", not "-1/max".
	if cloned.current_block < 0:
		cloned.current_block = cloned.max_block
	inventory.add_equipment(cloned)
	_auto_equip(cloned)


func _auto_equip(eq: Equipment) -> void:
	match eq.slot:
		Equipment.Slot.HEAD:
			if equipment_head == null: equipment_head = eq
		Equipment.Slot.CHEST:
			if equipment_chest == null: equipment_chest = eq
		Equipment.Slot.ARMS:
			if equipment_arms == null: equipment_arms = eq
		Equipment.Slot.LEGS:
			if equipment_legs == null: equipment_legs = eq
		Equipment.Slot.OFFHAND:
			if is_two_handed_equipped():
				return
			if _is_hand_free(hand_left):
				hand_left = eq
			elif _is_hand_free(hand_right):
				hand_right = eq
