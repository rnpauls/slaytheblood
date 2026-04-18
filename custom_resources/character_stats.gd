class_name CharacterStats
extends Stats

@export_group("Visuals")
@export_multiline var description: String
@export var portrait: Texture

@export_group("Gameplay Data")
@export var draftable_cards: CardPile
@export var starting_relic: Relic

func take_damage(damage : int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()

func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	instance.reset_action_points()
	instance.deck = instance.starting_deck.duplicate()
	instance.inventory = Inventory.new() #Weapons are added to characters, and the character adds it to their inventory
	#instance.starting_inventory.duplicate()
	for new_wep in instance.starting_inventory.weapons:
		instance.add_weapon(new_wep)
			
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	return instance
