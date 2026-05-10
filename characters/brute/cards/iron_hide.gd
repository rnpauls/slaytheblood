## Bulwark setup: gain block AND apply Thorns to self for the turn. The
## block amount is taken from `defense` so the card displays it in the corner
## (mirrors unyielding's pattern). Thorns retaliates against any physical hit
## the runeblade takes this turn — reflects equal to its stacks.
extends Card

const THORNS_STATUS = preload("res://statuses/thorns.tres")

@export var thorns_stacks: int = 2


func apply_effects(_targets: Array[Node], modifiers: ModifierHandler) -> void:
	if owner == null:
		return
	var mod_def := modifiers.get_modified_value(defense, Modifier.Type.BLOCK_GAINED)
	owner.stats.block += mod_def
	if owner.status_handler:
		var thorns := THORNS_STATUS.duplicate()
		thorns.stacks = thorns_stacks
		thorns.duration = 1
		owner.status_handler.add_status(thorns)
