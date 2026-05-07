## Pure runechant generator — no draw, just stack the field. Used by
## Spellbinding Bolt and any future "create N runechants" card. Targets SELF
## so the runechants land on the caster.
extends Card

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")

@export var runechant_amount: int = 2

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if runechant_amount <= 0:
		return
	var rune := RUNECHANT_STATUS.duplicate()
	rune.stacks = runechant_amount
	var status_effect := StatusEffect.new()
	status_effect.status = rune
	status_effect.execute(targets)
