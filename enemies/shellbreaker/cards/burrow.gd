## Burrow: NAA that grants the Shellbreaker block. Fires the standard
## BlockEffect path so BLOCK_GAINED modifiers (and downstream Brittle, etc.)
## apply consistently.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	apply_block_effects(targets, modifiers)
