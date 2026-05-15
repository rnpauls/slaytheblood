class_name CharacterStats
extends Stats

const GENERIC_DRAFTABLE_CARDS := preload("res://generic_cards/generic_draftable_cards.tres")

@export_group("Visuals")
@export_multiline var description: String
@export var portrait: Texture

@export_group("Gameplay Data")
@export var draftable_cards: CardPile
@export var draftable_equipment: Array[Equipment] = []
@export var draftable_weapons: Array[Weapon] = []
@export var starting_relic: Relic

func take_damage(damage : int, damage_kind: Card.DamageKind = Card.DamageKind.PHYSICAL, prevention: int = -1) -> int:
	var initial_health := health
	var damage_taken := super.take_damage(damage, damage_kind, prevention)
	if initial_health > health:
		Events.player_hit.emit()
	return damage_taken

func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	instance.reset_action_points()
	instance.deck = instance.starting_deck.custom_duplicate()
	instance.inventory = Inventory.new() # Items are added to the character, who adds them to their inventory.
	# Clear out any per-instance equipped slots so add_weapon/add_equipment can fill them fresh.
	instance.hand_left = null
	instance.hand_right = null
	instance.equipment_head = null
	instance.equipment_chest = null
	instance.equipment_arms = null
	instance.equipment_legs = null

	for new_wep in instance.starting_inventory.weapons:
		instance.add_weapon(new_wep)
	for new_eq in instance.starting_inventory.equips:
		instance.add_equipment(new_eq)

	var merged_draftable := CardPile.new()
	if draftable_cards:
		for draft_card in draftable_cards.cards:
			merged_draftable.cards.append(draft_card)
	for generic_card in GENERIC_DRAFTABLE_CARDS.cards:
		merged_draftable.cards.append(generic_card)
	instance.draftable_cards = merged_draftable

	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	return instance
