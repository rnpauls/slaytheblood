extends Card

const RUNECHANT_STATUS = preload("res://statuses/runechant.tres")

@export var runechant_amount: int = 1

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	# Draw 1 card.
	var card_draw := CardDrawEffect.new()
	card_draw.cards_to_draw = 1
	card_draw.execute([owner])

	# Add `runechant_amount` runechants to the owner. SELF targets resolves to
	# [owner], so we use the targets array as-is.
	var rune := RUNECHANT_STATUS.duplicate()
	rune.stacks = runechant_amount
	var status_effect := StatusEffect.new()
	status_effect.status = rune
	status_effect.execute(targets)
