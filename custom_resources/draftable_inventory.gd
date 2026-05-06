class_name DraftableInventory
extends Resource

## Cross-class pool of items that can drop from any character's post-battle reward.
## Combined with CharacterStats.draftable_equipment / draftable_weapons (class-specific)
## when BattleReward rolls an inventory drop.

@export var equipment: Array[Equipment] = []
@export var weapons: Array[Weapon] = []
