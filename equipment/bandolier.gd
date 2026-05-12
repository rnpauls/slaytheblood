## Bandolier: when used to block, discards the highest-attack card from your
## hand and grants block equal to that card's attack value. One-shot — destroyed
## after the trade. The brainstorm spec called for player choice ("may discard"),
## but auto-picking the biggest atk is the lower-friction default — same trade
## without a modal prompt.
class_name BandolierEquipment
extends Equipment


func consume_block_for_attack() -> int:
	used_this_attack = true
	var base_block := current_block
	current_block = 0
	if not owner or not (owner is Player):
		return base_block
	var hand_facade: HandFacade = owner.hand_facade
	if not hand_facade:
		return base_block
	var hand_arr := hand_facade.get_hand()
	var target_card: Card = null
	var highest_atk: int = 0
	for c: Card in hand_arr:
		if c.type == Card.Type.ATTACK and c.attack > highest_atk:
			highest_atk = c.attack
			target_card = c
	if target_card == null:
		return base_block
	hand_facade.discard_random_filtered(func(c: Card) -> bool: return c == target_card, 1)
	return base_block + highest_atk
