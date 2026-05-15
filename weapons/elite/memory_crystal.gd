## Memory Crystal — Mind Reaver elite weapon. Each landing on-hit pulls a
## random card from the target's draw pile and exhausts it. Pairs with Mind
## Reaver's MindAttrition opener (which already trims the player's deck) to
## attrit twice over: from the deck side (Memory Crystal) and the discard
## side (Bone Hook on Bone Knight). No arcane.
class_name MemoryCrystalWeapon
extends Weapon

const ON_HIT_ID := "memory_crystal_remove_deck"


func attach_to_combatant(_combatant: Combatant) -> void:
	var on_hit := OnHit.new()
	on_hit.id = ON_HIT_ID
	on_hit.custom_func = _on_hit_remove_deck
	# Higher than Bone Hook (3) — hitting cards before the player draws them
	# is a sharper threat than nibbling the discard cycle.
	on_hit.ai_value = 4
	on_hits = [on_hit]


func detach_from_combatant(_combatant: Combatant) -> void:
	on_hits = []


func _on_hit_remove_deck(target: Node, _args: Array) -> void:
	if target == null or not is_instance_valid(target):
		return
	var stats: Stats = target.get("stats")
	if stats == null or stats.draw_pile == null or stats.exhaust == null:
		return
	if stats.draw_pile.cards.is_empty():
		return
	var idx := randi() % stats.draw_pile.cards.size()
	var card: Card = stats.draw_pile.cards[idx]
	stats.draw_pile.cards.remove_at(idx)
	stats.draw_pile.card_pile_size_changed.emit(stats.draw_pile.cards.size())
	stats.exhaust.add_card(card)
	Events.card_exhausted.emit(card)
