## Bone Hook — Bone Knight signature. Each landing swing hooks one card out of
## the player's discard pile and dumps it into their exhaust pile, removing it
## from the rest of the battle. Different angle from Memory Crystal (which
## targets the deck) — Bone Hook attrits cards the player has already used,
## so even if they're cycling cleanly they'll see a slimmer cycle next loop.
##
## Pile membership matters: discard fuels the next reshuffle, exhaust does not.
## Moving discard → exhaust is the cleanest "remove for the rest of battle"
## without breaking pile invariants — the existing exhaust UI already renders
## these cards.
class_name BoneHookWeapon
extends Weapon

const ON_HIT_ID := "bone_hook_remove_discard"


func attach_to_combatant(_combatant: Combatant) -> void:
	var on_hit := OnHit.new()
	on_hit.id = ON_HIT_ID
	on_hit.custom_func = _on_hit_remove_discard
	# Ranks alongside other deck-attrition on-hits (gunkshot's add-trash
	# is ai_value 2). Slightly higher because removing a card the player
	# has already played is strictly worse for them than gaining a Trash.
	on_hit.ai_value = 3
	on_hits = [on_hit]


func detach_from_combatant(_combatant: Combatant) -> void:
	on_hits = []


func _on_hit_remove_discard(target: Node, _args: Array) -> void:
	if target == null or not is_instance_valid(target):
		return
	var stats: Stats = target.get("stats")
	if stats == null or stats.discard == null or stats.exhaust == null:
		return
	if stats.discard.cards.is_empty():
		return
	var idx := randi() % stats.discard.cards.size()
	var card: Card = stats.discard.cards[idx]
	stats.discard.cards.remove_at(idx)
	stats.discard.card_pile_size_changed.emit(stats.discard.cards.size())
	stats.exhaust.add_card(card)
	Events.card_exhausted.emit(card)
