## Runechants as scaling stat. Read the runechant stack count and grant the
## runeblade that much Empower for the next attack — without consuming the
## runechants. Setup card for a big detonation turn: pile up runechants, then
## Runesurge → big attack that lands +Empower physical AND consumes runechants
## for bonus arcane.
extends Card

const EMPOWER_STATUS = preload("res://statuses/empowered.tres")


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.status_handler == null:
		return
	var rune := owner.status_handler.get_status_by_id("runechant")
	if not (rune is RunechantStatus):
		return
	var amount: int = (rune as RunechantStatus).stacks
	if amount <= 0:
		return
	var empower := EMPOWER_STATUS.duplicate()
	empower.stacks = amount
	empower.duration = 1
	owner.status_handler.add_status(empower)
