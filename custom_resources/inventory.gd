class_name Inventory
extends Resource

#signal inventory_changed()

@export var weapons: Array[Weapon] =[]
#@export var equips: Array[Equipment] =[]

func empty() -> bool:
	return weapons.is_empty() #and equips ie empty

#func draw_card() -> Card:
	#var card = cards.pop_front()
	#if card:
		#print("Drew card %s" % card.id)
		#card_pile_size_changed.emit(cards.size())
	#return card

func add_weapon(weapon: Weapon) -> void:
	weapons.append(weapon)
	#inventory_changed.emit()

#func shuffle() -> void:
	#RNG.array_shuffle(cards)

func clear() -> void:
	weapons.clear()
	#card_pile_size_changed.emit(cards.size())

#Duplicate doesn't actually work so we need this
# https://github.com/godotengine/godot/issues/74918
#func duplicate_() -> Array[Card]:
	#var new_array: Array[Card] = []
	#
	#for card: Card in cards:
		#new_array.append(card.duplicate())
	#
	#return new_array

# We need this method because of a Godot issue
# reported here: 
# https://github.com/godotengine/godot/issues/74918
#func custom_duplicate() -> CardPile:
	#var new_card_pile := CardPile.new()
	#new_card_pile.cards = duplicate_cards()
	#
	#return new_card_pile

func _to_string() -> String:
	var _weapon_strings: PackedStringArray = []
	for i in range(weapons.size()):
		_weapon_strings.append("%s: %s" % [i+1, weapons[i].id])
	return "\n".join(_weapon_strings)

#func reveal_top_cards(num_to_reveal : int) -> Array[Card]:
	#if num_to_reveal <= 0:
		#return []
	#else:
		#return cards.slice(0,num_to_reveal)

func has_weapon(id: String) -> bool:
	print("need to update has_weapon to check equipment")
	for tmp_wep in weapons as Array[Weapon]:
		if tmp_wep and (tmp_wep.id == id) and is_instance_valid(tmp_wep) : 
			return true
	return false
