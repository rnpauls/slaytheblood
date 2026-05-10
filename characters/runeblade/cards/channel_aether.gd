## Mana-gated runechant create. Base 2 runechants; if the runeblade still has
## `mana_threshold`+ mana available after paying cost, create `bonus_amount`
## instead. Rewards pitching cheap cards before playing — fits high-pitch
## Runeblade hands.
extends Card

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")

@export var base_amount: int = 2
@export var bonus_amount: int = 4
@export var mana_threshold: int = 3


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var amount := base_amount
	if owner and owner.stats and owner.stats.mana >= mana_threshold:
		amount = bonus_amount
	if amount <= 0:
		return
	var rune := RUNECHANT_STATUS.duplicate()
	rune.stacks = amount
	var status_effect := StatusEffect.new()
	status_effect.status = rune
	status_effect.execute(targets)
